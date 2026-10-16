import 'dart:math';

import '../../core/utils/calendar_date_helpers.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_draft.dart';
import '../../domain/entities/team_member.dart';

abstract final class MockData {
  static const List<TeamMember> members = [
    TeamMember(id: 'm01', name: 'Akhil Bisht'),
    TeamMember(id: 'm02', name: 'Bilal Shaikh'),
    TeamMember(id: 'm03', name: 'Deepak Singh'),
    TeamMember(id: 'm04', name: 'Hemant Kumar'),
    TeamMember(id: 'm05', name: 'Aanand Bhatt'),
  ];

  static const AppUser admin = AppUser(
    id: 'u_admin',
    name: 'Team Manager',
    role: UserRole.admin,
  );

  static final List<AppUser> users = [
    admin,
    for (final m in members)
      AppUser(
        id: 'u_${m.id}',
        name: m.name,
        role: UserRole.teamMember,
        memberId: m.id,
      ),
  ];

  static const List<TaskTemplate> templates = [
    TaskTemplate(
      id: 'tpl_site_visit',
      title: 'Schedule a site visit with the client',
      description: 'Confirm the slot with the owner and share the location.',
    ),
    TaskTemplate(
      id: 'tpl_availability',
      title: 'Check if the apartment is available',
      description: 'Confirm availability and key handover with the owner.',
    ),
    TaskTemplate(
      id: 'tpl_documents',
      title: 'Verify ownership documents',
      description: 'Collect and verify sale deed, tax receipts and NOC.',
    ),
    TaskTemplate(
      id: 'tpl_agreement',
      title: 'Collect signed lease agreement from the tenant',
    ),
    TaskTemplate(
      id: 'tpl_listing',
      title: 'Update the listing price on all portals',
    ),
  ];

  static const PortfolioSummary portfolio = PortfolioSummary(
    allListings: 8,
    underOnboarding: 5,
    toRentIn: OpportunityGroup(count: 12, memberIds: ['m02', 'm03', 'm01']),
    toLeaseOut: OpportunityGroup(count: 4, memberIds: ['m04', 'm05']),
  );

  static const List<String> _titles = [
    'Check if the Oberoi Splendors is available this week with the keys.',
    'Create a Facebook ad campaign targeting young professionals in the city.',
    'Check if the apartment is available',
    'Schedule a site visit for the Powai 2BHK with the Mehta family.',
    'Collect signed lease agreement from the tenant at Lodha Park.',
    'Share updated rental comps for Bandra West with the owner.',
    'Follow up on the security deposit refund for flat 1204.',
    'Arrange a photoshoot for the new Andheri listing.',
    'Verify ownership documents for the Juhu bungalow.',
    'Call the society secretary about the NOC for Hiranandani Gardens.',
    'Prepare the move-in checklist for the Worli sea-facing unit.',
    'Negotiate brokerage terms with the Thane developer.',
    'Update the listing price for the Chembur 3BHK on all portals.',
    'Send the onboarding welcome kit to the new landlord.',
    'Inspect plumbing issues reported at Kanjurmarg apartment.',
    'Renew the rental agreement for the Malad West tenant.',
  ];

  static List<Task> tasks(DateTime now) {
    final random = Random(42);
    final endOfToday = now.startOfNextDay.subtract(const Duration(minutes: 1));
    final tasks = <Task>[];
    var seq = 0;

    DateTime clampToNow(DateTime d) => d.isAfter(now) ? now : d;

    for (var m = 0; m < members.length; m++) {
      final memberId = members[m].id;
      final count = 16 + m * 3;
      for (var i = 0; i < count; i++) {
        seq++;
        final id = 't${seq.toString().padLeft(3, '0')}';
        final title = _titles[(seq * 7 + m) % _titles.length];
        DateTime? due;
        DateTime? completed;

        switch ((i + m) % 8) {
          case 0:
            final candidate = now.add(Duration(hours: 1 + random.nextInt(5)));
            due = candidate.isAfter(endOfToday) ? endOfToday : candidate;
          case 1:
            due = now.subtract(
              Duration(days: 1 + random.nextInt(20), hours: random.nextInt(8)),
            );
          case 2:
            due = now.subtract(Duration(hours: 1 + random.nextInt(30)));
          case 3:
            due = now.add(
              Duration(days: 1 + random.nextInt(25), hours: random.nextInt(8)),
            );
          case 4:
            due = now.add(Duration(days: 30 + random.nextInt(120)));
          case 5:
            due = null;
          case 6:
            due = now.subtract(Duration(days: random.nextInt(4)));
            completed = now.subtract(Duration(hours: random.nextInt(60)));
          default:
            due = now.subtract(Duration(days: 10 + random.nextInt(200)));
            completed = due.add(Duration(hours: random.nextInt(72) - 24));
        }

        if (completed != null) completed = clampToNow(completed);
        final anchor = completed ?? due ?? now;
        final created = clampToNow(
          anchor.subtract(Duration(days: 2 + random.nextInt(30))),
        );

        tasks.add(
          Task(
            id: id,
            title: title,
            assigneeId: memberId,
            createdAt: created,
            dueAt: due,
            status: completed == null ? TaskStatus.open : TaskStatus.closed,
            completedAt: completed,
          ),
        );
      }
    }
    return tasks;
  }
}
