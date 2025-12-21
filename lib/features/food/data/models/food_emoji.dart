/// Food emoji options for categorizing meals and freezer items
enum FoodEmoji {
  // Main proteins
  chicken('🍗', 'Kylling'),
  beef('🥩', 'Oksekød'),
  pork('🥓', 'Svinekød'),
  fish('🐟', 'Fisk'),
  shrimp('🦐', 'Rejer'),
  eggs('🥚', 'Æg'),
  
  // Asian/International
  chopsticks('🥢', 'Asiatisk'),
  sushi('🍣', 'Sushi'),
  ramen('🍜', 'Nudler'),
  curry('🍛', 'Karry'),
  taco('🌮', 'Taco'),
  burrito('🌯', 'Burrito'),
  
  // Italian
  pizza('🍕', 'Pizza'),
  pasta('🍝', 'Pasta'),
  
  // Fast food
  burger('🍔', 'Burger'),
  hotdog('🌭', 'Hotdog'),
  fries('🍟', 'Pomfritter'),
  sandwich('🥪', 'Sandwich'),
  
  // Vegetables & Vegetarian
  salad('🥗', 'Salat'),
  broccoli('🥦', 'Grøntsager'),
  carrot('🥕', 'Gulerødder'),
  corn('🌽', 'Majs'),
  potato('🥔', 'Kartofler'),
  
  // Bread & Grains
  bread('🍞', 'Brød'),
  rice('🍚', 'Ris'),
  croissant('🥐', 'Croissant'),
  
  // Fruits
  apple('🍎', 'Frugt'),
  banana('🍌', 'Banan'),
  strawberry('🍓', 'Jordbær'),
  
  // Soups & Stews
  soup('🍲', 'Suppe/Gryde'),
  fondue('🫕', 'Fondue'),
  
  // Desserts
  cake('🍰', 'Kage'),
  iceCream('🍨', 'Is'),
  cookie('🍪', 'Småkager'),
  
  // Drinks (for freezer)
  juice('🧃', 'Juice'),
  
  // General
  plate('🍽️', 'Andet'),
  chef('👨‍🍳', 'Hjemmelavet'),
  takeout('🥡', 'Takeaway'),
  ;

  const FoodEmoji(this.emoji, this.label);
  
  final String emoji;
  final String label;
  
  /// Get emoji by name
  static FoodEmoji fromName(String name) {
    return FoodEmoji.values.firstWhere(
      (e) => e.name == name,
      orElse: () => FoodEmoji.plate,
    );
  }
}

/// Quantity units for freezer items
enum QuantityUnit {
  stk('stk', 'Styk'),
  kg('kg', 'Kilogram'),
  poser('poser', 'Poser'),
  pakker('pakker', 'Pakker'),
  liter('L', 'Liter'),
  gram('g', 'Gram'),
  ;

  const QuantityUnit(this.abbreviation, this.label);
  
  final String abbreviation;
  final String label;
  
  static QuantityUnit fromName(String name) {
    return QuantityUnit.values.firstWhere(
      (e) => e.name == name,
      orElse: () => QuantityUnit.stk,
    );
  }
}
