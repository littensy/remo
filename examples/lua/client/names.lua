local names = {
	"Milk",
	"Eggs",
	"Bread",
	"Butter",
	"Cheese",
	"Bacon",
	"Sausage",
	"Ham",
	"Chicken",
	"Beef",
	"Pork",
	"Fish",
	"Rice",
	"Pasta",
	"Potatoes",
	"Onions",
	"Garlic",
	"Tomatoes",
	"Carrots",
	"Peppers",
	"Lettuce",
	"Cucumber",
	"Mushrooms",
	"Spinach",
	"Broccoli",
	"Cauliflower",
	"Celery",
	"Apples",
	"Oranges",
	"Bananas",
	"Grapes",
	"Strawberries",
	"Blueberries",
	"Raspberries",
	"Pineapple",
	"Peaches",
	"Pears",
	"Cherries",
	"Watermelon",
	"Cantaloupe",
	"Honeydew",
	"Lemons",
	"Limes",
	"Avocado",
	"Corn",
	"Beans",
	"Peas",
	"Nuts",
	"Seeds",
	"Olive Oil",
	"Vegetable Oil",
	"Butter",
	"Margarine",
	"Flour",
	"Sugar",
	"Salt",
	"Pepper",
	"Spices",
	"Herbs",
	"Baking Powder",
	"Baking Soda",
	"Yeast",
	"Vanilla Extract",
	"Chocolate",
	"Cocoa Powder",
	"Coffee",
	"Tea",
	"Juice",
	"Milk",
	"Cream",
	"Soda",
	"Water",
	"Ice",
	"Bottled Water",
	"Toilet Paper",
	"Paper Towels",
	"Tissues",
	"Soap",
	"Shampoo",
	"Conditioner",
	"Toothpaste",
	"Toothbrush",
	"Mouthwash",
	"Floss",
	"Deodorant",
	"Razors",
	"Shaving Cream",
	"Lotion",
	"Sunscreen",
	"Makeup",
	"Cotton Swabs",
	"Cotton Balls",
	"Nail Polish",
	"Nail Polish Remover",
	"Batteries",
	"Light Bulbs",
	"Trash Bags",
	"Laundry Detergent",
	"Fabric Softener",
	"Dish Soap",
	"Dishwasher Detergent",
	"Sponges",
	"Dish Towels",
}

local function getRandomName()
	return names[math.random(#names)]
end

return {
	getRandomName = getRandomName,
}
