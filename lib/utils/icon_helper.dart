import 'package:flutter/material.dart';

class IconHelper {
  /// Convert an integer code back into an IconData.
  static IconData getIcon(int code) {
    return IconData(code, fontFamily: 'MaterialIcons');
  }

  /// Returns a large collection of Material icons.
  static List<IconData> get availableIcons => [
    Icons.restaurant,
    Icons.fastfood,
    Icons.local_cafe,
    Icons.local_bar,
    Icons.cake,
    Icons.lunch_dining,
    Icons.ramen_dining,
    Icons.icecream,
    Icons.bakery_dining,
    Icons.emoji_food_beverage,

    Icons.shopping_cart,
    Icons.shopping_bag,
    Icons.store,
    Icons.local_mall,
    Icons.checkroom,

    Icons.directions_car,
    Icons.local_taxi,
    Icons.train,
    Icons.directions_bus,
    Icons.flight,
    Icons.two_wheeler,
    Icons.electric_bike,
    Icons.local_gas_station,

    Icons.home,
    Icons.chair,
    Icons.bed,
    Icons.kitchen,
    Icons.cleaning_services,

    Icons.medical_services,
    Icons.local_hospital,
    Icons.medication,
    Icons.health_and_safety,
    Icons.favorite,

    Icons.school,
    Icons.menu_book,
    Icons.calculate,
    Icons.science,

    Icons.sports_soccer,
    Icons.sports_basketball,
    Icons.sports_tennis,
    Icons.fitness_center,
    Icons.pool,

    Icons.movie,
    Icons.music_note,
    Icons.headphones,
    Icons.tv,
    Icons.games,
    Icons.videogame_asset,

    Icons.work,
    Icons.business,
    Icons.badge,
    Icons.laptop,
    Icons.computer,

    Icons.account_balance_wallet,
    Icons.attach_money,
    Icons.payments,
    Icons.credit_card,
    Icons.savings,
    Icons.currency_exchange,
    Icons.trending_up,

    Icons.pets,
    Icons.child_care,
    Icons.family_restroom,

    Icons.card_giftcard,
    Icons.celebration,
    Icons.redeem,

    Icons.phone_android,
    Icons.devices,
    Icons.watch,
    Icons.tablet_mac,

    Icons.water_drop,
    Icons.flash_on,
    Icons.wifi,
    Icons.lightbulb,

    Icons.travel_explore,
    Icons.luggage,
    Icons.beach_access,
    Icons.hotel,

    Icons.local_florist,
    Icons.park,
    Icons.eco,

    Icons.star,
    Icons.favorite_border,
    Icons.thumb_up,
    Icons.face,

    Icons.more_horiz,
  ];
}
