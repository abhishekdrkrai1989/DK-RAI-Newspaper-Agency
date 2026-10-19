import 'package:flutter_test/flutter_test.dart';
import 'package:newspaper_delivery_app/models/app_user.dart';
import 'package:newspaper_delivery_app/models/approval_request.dart';
import 'package:newspaper_delivery_app/models/customer.dart';
import 'package:newspaper_delivery_app/providers/delivery_provider.dart';
import 'package:newspaper_delivery_app/services/local_storage_service.dart';

void main() {
  group('Two-Role Login & Approval System Tests', () {
    late LocalStorageService storage;
    late DeliveryProvider provider;

    setUp(() async {
      storage = await LocalStorageService.init(inMemoryForTests: true);
      provider = DeliveryProvider(storage);
    });

    test('Default users are configured with correct roles and PINs', () {
      expect(provider.allUsers.length, 2);

      final owner = provider.allUsers.firstWhere((u) => u.isOwner);
      expect(owner.name, 'D K Rai (Owner)');
      expect(owner.pin, '1234');
      expect(owner.role, UserRole.owner);

      final deliveryBoy = provider.allUsers.firstWhere((u) => u.isDeliveryBoy);
      expect(deliveryBoy.name, 'Ramesh (Delivery Boy)');
      expect(deliveryBoy.pin, '0000');
      expect(deliveryBoy.role, UserRole.deliveryBoy);
    });

    test('Login PIN validation works for Owner and Delivery Boy', () async {
      final owner = provider.allUsers.firstWhere((u) => u.isOwner);
      final deliveryBoy = provider.allUsers.firstWhere((u) => u.isDeliveryBoy);

      // Wrong PIN fails
      final wrongRes = await provider.login(owner.id, '9999');
      expect(wrongRes, isFalse);

      // Correct Owner PIN succeeds
      final ownerRes = await provider.login(owner.id, '1234');
      expect(ownerRes, isTrue);
      expect(provider.isLoggedIn, isTrue);
      expect(provider.isOwner, isTrue);
      expect(provider.isDeliveryBoy, isFalse);

      // Logout works
      await provider.logout();
      expect(provider.isLoggedIn, isFalse);
      expect(provider.currentUser, isNull);

      // Delivery Boy login succeeds
      final boyRes = await provider.login(deliveryBoy.id, '0000');
      expect(boyRes, isTrue);
      expect(provider.isLoggedIn, isTrue);
      expect(provider.isOwner, isFalse);
      expect(provider.isDeliveryBoy, isTrue);
    });

    test('Delivery Boy actions generate pending Approval Requests for Owner',
        () async {
      final deliveryBoy = provider.allUsers.firstWhere((u) => u.isDeliveryBoy);
      final owner = provider.allUsers.firstWhere((u) => u.isOwner);

      // Log in as Delivery Boy
      await provider.login(deliveryBoy.id, '0000');
      expect(provider.isDeliveryBoy, isTrue);
      expect(provider.pendingApprovalsCount, 0);

      // 1. Delivery Boy pauses a customer paper
      final cust = provider.allCustomers.first;
      await provider.pauseCustomerPaper(cust.id, reason: 'Customer out of town');

      // Verify action took immediate route effect AND submitted approval request
      expect(provider.pendingApprovalsCount, 1);
      final req = provider.pendingApprovals.first;
      expect(req.actionType, ApprovalActionType.pausePaper);
      expect(req.requestedBy, 'Ramesh (Delivery Boy)');
      expect(req.status, ApprovalStatus.pending);

      // 2. Switch to Owner and Approve action
      await provider.login(owner.id, '1234');
      expect(provider.isOwner, isTrue);
      expect(provider.pendingApprovalsCount, 1);

      await provider.approveRequest(req.id);
      expect(provider.pendingApprovalsCount, 0);
      expect(provider.approvalRequests.first.isApproved, isTrue);
      expect(provider.approvalRequests.first.reviewedBy, 'D K Rai (Owner)');
    });

    test('Owner rejecting a Delivery Boy action reverts the action',
        () async {
      final deliveryBoy = provider.allUsers.firstWhere((u) => u.isDeliveryBoy);
      final owner = provider.allUsers.firstWhere((u) => u.isOwner);

      // Log in as Delivery Boy
      await provider.login(deliveryBoy.id, '0000');
      final cust = provider.allCustomers.first;
      expect(cust.status, DeliveryStatus.started);

      // Delivery Boy pauses paper
      await provider.pauseCustomerPaper(cust.id, reason: 'Temporary stop');
      expect(provider.allCustomers.firstWhere((c) => c.id == cust.id).status,
          DeliveryStatus.paused);
      expect(provider.pendingApprovalsCount, 1);

      final reqId = provider.pendingApprovals.first.id;

      // Log in as Owner and Reject the pause request
      await provider.login(owner.id, '1234');
      await provider.rejectRequest(reqId, reason: 'Incorrect customer');

      // Verify request is rejected AND customer status was reverted to started!
      expect(provider.pendingApprovalsCount, 0);
      expect(provider.approvalRequests.first.isRejected, isTrue);
      final revertedCust =
          provider.allCustomers.firstWhere((c) => c.id == cust.id);
      expect(revertedCust.status, DeliveryStatus.started);
    });

    test('Owner can approve all pending actions in bulk', () async {
      final deliveryBoy = provider.allUsers.firstWhere((u) => u.isDeliveryBoy);
      final owner = provider.allUsers.firstWhere((u) => u.isOwner);

      // Delivery Boy performs two actions
      await provider.login(deliveryBoy.id, '0000');
      await provider.pauseCustomerPaper(provider.allCustomers[0].id);
      await provider.pauseCustomerPaper(provider.allCustomers[1].id);
      expect(provider.pendingApprovalsCount, 2);

      // Owner approves all
      await provider.login(owner.id, '1234');
      await provider.approveAllPending();
      expect(provider.pendingApprovalsCount, 0);
      expect(provider.approvalRequests.where((r) => r.isApproved).length, 2);
    });

    test('Owner actions do not generate pending approval requests', () async {
      final owner = provider.allUsers.firstWhere((u) => u.isOwner);
      await provider.login(owner.id, '1234');

      // Owner pauses a paper directly
      await provider.pauseCustomerPaper(provider.allCustomers.first.id);

      // No approval request needed since Owner made the change
      expect(provider.pendingApprovalsCount, 0);
    });

    test('ApprovalRequest toRow and fromRow accurately preserve data for Supabase cloud sync', () {
      final req = ApprovalRequest(
        id: 'req_12345',
        actionType: ApprovalActionType.addCustomer,
        title: 'New Customer: Sharma Ji',
        description: 'House 102, Block A',
        targetId: 'cust_999',
        requestedBy: 'Ramesh (Delivery Boy)',
        requestedAt: DateTime.parse('2026-10-19 10:30:00'),
        status: ApprovalStatus.pending,
        payload: {'name': 'Sharma Ji', 'block': 'A'},
      );

      final row = req.toRow();
      expect(row['id'], 'req_12345');
      expect(row['action_type'], 'addCustomer');
      expect(row['target_id'], 'cust_999');
      expect(row['requested_by'], 'Ramesh (Delivery Boy)');
      expect(row['status'], 'pending');
      expect(row['payload']['name'], 'Sharma Ji');

      final reconstructed = ApprovalRequest.fromRow(row);
      expect(reconstructed.id, req.id);
      expect(reconstructed.actionType, req.actionType);
      expect(reconstructed.title, req.title);
      expect(reconstructed.description, req.description);
      expect(reconstructed.targetId, req.targetId);
      expect(reconstructed.requestedBy, req.requestedBy);
      expect(reconstructed.status, req.status);
      expect(reconstructed.payload['name'], 'Sharma Ji');
    });
  });
}
