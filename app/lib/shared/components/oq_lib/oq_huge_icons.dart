import 'package:hugeicons/hugeicons.dart';

enum OQHugeIcon {
  home,
  inbox,
  reminder,
  schedule,
  shoppingBag,
  calendar,
  add,
  emptyInbox,
}

extension OQHugeIconData on OQHugeIcon {
  List<List<dynamic>> get data {
    switch (this) {
      case OQHugeIcon.home:
        return HugeIcons.strokeRoundedHome01;
      case OQHugeIcon.inbox:
        return HugeIcons.strokeRoundedInbox;
      case OQHugeIcon.reminder:
        return HugeIcons.strokeRoundedReminder;
      case OQHugeIcon.schedule:
        return HugeIcons.strokeRoundedCalendar04;
      case OQHugeIcon.shoppingBag:
        return HugeIcons.strokeRoundedShoppingBag01;
      case OQHugeIcon.calendar:
        return HugeIcons.strokeRoundedCalendar01;
      case OQHugeIcon.add:
        return HugeIcons.strokeRoundedAdd01;
      case OQHugeIcon.emptyInbox:
        return HugeIcons.strokeRoundedInbox;
    }
  }
}
