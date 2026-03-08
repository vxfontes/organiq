import 'package:hugeicons/hugeicons.dart';

enum IBHugeIcon {
  home,
  inbox,
  reminder,
  schedule,
  shoppingBag,
  calendar,
  add,
  emptyInbox,
}

extension IBHugeIconData on IBHugeIcon {
  List<List<dynamic>> get data {
    switch (this) {
      case IBHugeIcon.home:
        return HugeIcons.strokeRoundedHome01;
      case IBHugeIcon.inbox:
        return HugeIcons.strokeRoundedInbox;
      case IBHugeIcon.reminder:
        return HugeIcons.strokeRoundedReminder;
      case IBHugeIcon.schedule:
        return HugeIcons.strokeRoundedCalendar04;
      case IBHugeIcon.shoppingBag:
        return HugeIcons.strokeRoundedShoppingBag01;
      case IBHugeIcon.calendar:
        return HugeIcons.strokeRoundedCalendar01;
      case IBHugeIcon.add:
        return HugeIcons.strokeRoundedAdd01;
      case IBHugeIcon.emptyInbox:
        return HugeIcons.strokeRoundedInbox;
    }
  }
}
