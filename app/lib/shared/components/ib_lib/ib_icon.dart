import 'package:flutter/material.dart';

import 'package:inbota/shared/theme/app_colors.dart';

class IBIcon extends StatelessWidget {
  const IBIcon(
    this.icon, {
    super.key,
    this.size = 20,
    this.color,
    this.backgroundColor,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.borderColor,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? borderColor;

  static const IconData alarmOutlined = Icons.alarm_outlined;
  static const IconData addRounded = Icons.add_rounded;
  static const IconData arrowBackRounded = Icons.arrow_back_rounded;
  static const IconData arrowForwardRounded = Icons.arrow_forward_rounded;
  static const IconData autoAwesomeRounded = Icons.auto_awesome_rounded;
  static const IconData checkRounded = Icons.check_rounded;
  static const IconData chevronRight = Icons.chevron_right;
  static const IconData creditCard = Icons.credit_card;
  static const IconData deleteOutlineRounded = Icons.delete_outline_rounded;
  static const IconData closeRounded = Icons.close_rounded;
  static const IconData eventAvailableOutlined = Icons.event_available_outlined;
  static const IconData gridViewRounded = Icons.grid_view_rounded;
  static const IconData helpOutline = Icons.help_outline;
  static const IconData lockOutline = Icons.lock_outline;
  static const IconData mailOutline = Icons.mail_outline;
  static const IconData micRounded = Icons.mic_rounded;
  static const IconData notificationsActiveRounded =
      Icons.notifications_active_rounded;
  static const IconData notificationsNoneOutlined =
      Icons.notifications_none_outlined;
  static const IconData personOutline = Icons.person_outline;
  static const IconData privacyTipOutlined = Icons.privacy_tip_outlined;
  static const IconData shoppingBagOutlined = Icons.shopping_bag_outlined;
  static const IconData starRounded = Icons.star_rounded;
  static const IconData stickyNote2Outlined = Icons.sticky_note_2_outlined;
  static const IconData stopCircleRounded = Icons.stop_circle_rounded;
  static const IconData taskAltRounded = Icons.task_alt_rounded;
  static const IconData tune = Icons.tune;
  static const IconData verifiedUserOutlined = Icons.verified_user_outlined;
  static const IconData repeatRounded = Icons.repeat_rounded;
  static const IconData checkCircleOutlineRounded = Icons.check_circle_outline_rounded;
  static const IconData errorOutlineRounded = Icons.error_outline_rounded;
  static const IconData editOutlineRounded = Icons.edit_outlined;
  static const IconData refreshRounded = Icons.refresh_rounded;
  static const IconData calendarMonthRounded = Icons.calendar_month_rounded;
  static const IconData calendarTodayRounded = Icons.calendar_today_rounded;
  static const IconData skipNextRounded = Icons.skip_next_rounded;
  static const IconData calendar = Icons.calendar_today_outlined;
  static const IconData fire = Icons.local_fire_department_outlined;
  static const IconData mailOutlineRounded = Icons.mail_outline_rounded;
  static const IconData keyRounded = Icons.key_rounded;
  static const IconData autoRenew = Icons.autorenew_rounded;
  static const IconData linkRounded = Icons.link_rounded;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.text;
    final iconWidget = Icon(icon, size: size, color: resolvedColor);

    final needsContainer =
        backgroundColor != null ||
        padding != EdgeInsets.zero ||
        borderColor != null;

    if (!needsContainer) return iconWidget;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.transparent,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: iconWidget,
    );
  }
}
