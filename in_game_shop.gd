extends Node2D

# Max amount of itens on panel, without scrolling
const max_amount_vertically = 8

# Store itens available enum
enum Adquirance {
	MUSHROOM,
	MUSHROOM_5x,
	RING,
	RING_10x,
	GREEN_MUSHROOM,
	GREEN_MUSHROOM_5x,
	GREEN_MUSHROOM_10x,
	GREEN_MUSHROOM_20x,
	LEAF,
	LEAF_5x,
	LEAF_10x,
}

var adquirances = []
var menu_left_items = []
var menu_right_items = []
var menu_left_scroll_top = 0
var menu_right_scroll_top = 0
var selectedItemIndex = 0
var focusInitialPosition = 0
var game_state = null
var coin_available = 800 # FIXME zero
var coin_transfering = 0
var salesman_talking = 0

# Store itens available on this store
var salesman_store = [
	Adquirance.MUSHROOM,
	Adquirance.MUSHROOM_5x,
	Adquirance.RING,
	Adquirance.RING_10x,
	Adquirance.GREEN_MUSHROOM,
	Adquirance.GREEN_MUSHROOM_5x,
	Adquirance.GREEN_MUSHROOM_10x,
	Adquirance.GREEN_MUSHROOM_20x,
	Adquirance.LEAF,
	Adquirance.LEAF_5x,
	Adquirance.LEAF_10x,
]

# Internationalization messages
var i18n_messages = {
	'MUSHROOM': 'Mushroom',
	'MUSHROOM_5x': 'Mushroom 5x',
	'RING': 'Ring',
	'RING_10x': 'Ring 10x',
	'GREEN_MUSHROOM': 'Green Mushroom',
	'GREEN_MUSHROOM_5x': 'Green Mushroom 5x',
	'GREEN_MUSHROOM_10x': 'Green Mushroom 10x',
	'GREEN_MUSHROOM_20x': 'Green Mushroom 20x',
	'LEAF': 'Leaf',
	'LEAF_5x': 'Leaf 5x',
	'LEAF_10x': 'Leaf 10x',
	'THX': 'Thanks!',
	'NOT_ENOUGHT_COINS': 'Not enough coins.'
}

# price mapping
var price_table = [
	{
		'item': Adquirance.MUSHROOM,
		'price': 30
	},
	{
		'item': Adquirance.MUSHROOM_5x,
		'price': 70
	},
	{
		'item': Adquirance.RING,
		'price': 90
	},
	{
		'item': Adquirance.RING_10x,
		'price': 140
	},
	{
		'item': Adquirance.GREEN_MUSHROOM,
		'price': 60
	},
	{
		'item': Adquirance.GREEN_MUSHROOM_5x,
		'price': 90
	},
	{
		'item': Adquirance.GREEN_MUSHROOM_10x,
		'price': 120
	},
	{
		'item': Adquirance.GREEN_MUSHROOM_20x,
		'price': 120
	},	
	{
		'item': Adquirance.LEAF,
		'price': 50
	},
	{
		'item': Adquirance.LEAF_5x,
		'price': 200
	},
]

# Called when the node enters the scene tree for the first time.
func _ready():
	rearrange_store()
	focusInitialPosition = $MenuRight/Selection.position.y
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if coin_transfering > 0:
		coin_available -= 1
		coin_transfering -= 1
		$CoinPanel/Label.text = str(coin_available)
	else:
		if Input.is_action_just_released("ui_down"):
			selectedItemIndex += 1
			$PopAudio.play()
		if Input.is_action_just_released("ui_up"):
			selectedItemIndex -= 1
			$PopAudio.play()
		if Input.is_action_just_released("ui_accept"):			
			buy_item(salesman_store[selectedItemIndex + menu_right_scroll_top])
			$PopAudio.play()
	if selectedItemIndex < 0:
		selectedItemIndex = 0
		if menu_right_scroll_top > 0:
			menu_left_scroll_top -= 1
			do_menu_right_scroll_up()
	if selectedItemIndex > salesman_store.size():
		selectedItemIndex = salesman_store.size()
	if (selectedItemIndex + menu_right_scroll_top) > (salesman_store.size()-1):
		selectedItemIndex -= 1
	if selectedItemIndex > (max_amount_vertically-1):
		do_menu_right_scroll_down()
		selectedItemIndex = (max_amount_vertically-1)
	$MenuRight/Selection.position.y = focusInitialPosition + (selectedItemIndex * 35)
	if salesman_talking > 0:
		salesman_talking -= 1
		if salesman_talking == 0:
			$SalesmanDialog.visible = false
	pass
	
	
func do_menu_right_scroll_down():
	menu_right_scroll_top += 1
	rearrange_store()
	
	
func do_menu_right_scroll_up():
	menu_right_scroll_top -= 1
	rearrange_store()


func get_item_name(item):
	match item:
		'mushroom':
			return i18n_messages['MUSHROOM']
		'ring':
			return i18n_messages['RING']
		'green_mushroom':
			return i18n_messages['GREEN_MUSHROOM']
		'leaf':
			return i18n_messages['LEAF']
		Adquirance.MUSHROOM:
			return i18n_messages['MUSHROOM']
		Adquirance.MUSHROOM_5x:
			return i18n_messages['MUSHROOM_5x']
		Adquirance.RING:
			return i18n_messages['RING']
		Adquirance.RING_10x:
			return i18n_messages['RING_10x']
		Adquirance.GREEN_MUSHROOM:
			return i18n_messages['GREEN_MUSHROOM']
		Adquirance.GREEN_MUSHROOM_5x:
			return i18n_messages['GREEN_MUSHROOM_5x']
		Adquirance.GREEN_MUSHROOM_10x:
			return i18n_messages['GREEN_MUSHROOM_10x']
		Adquirance.GREEN_MUSHROOM_20x:
			return i18n_messages['GREEN_MUSHROOM_20x']
		Adquirance.LEAF:
			return i18n_messages['LEAF']
		Adquirance.LEAF_5x:
			return i18n_messages['LEAF_5x']
		Adquirance.LEAF_10x:
			return i18n_messages['LEAF_10x']
	return ""


func get_product_price(item):
	for price_table_item in price_table:
		if price_table_item['item'] == item:
			return price_table_item['price']
	return 0 


func rearrange_store():
	$CoinPanel/Label.text = str(coin_available)
	var amount = 0
	for item in menu_right_items:
		$MenuRight.remove_child(item['node']) 
	for item in menu_left_items:
		$MenuLeft.remove_child(item['node']) 
	menu_right_items = []
	var scrolling = menu_right_scroll_top
	for item in salesman_store:
		if scrolling > 0:
			scrolling -= 1
			continue
		var item_node = $MenuRight/Item.duplicate()
		var in_list_item = {
			'kind': item,
			'node': item_node
		}
		menu_right_items.push_back(in_list_item)
		if amount < max_amount_vertically:
			$MenuRight.add_child(item_node)
			item_node.position.y += 35 * amount
			item_node.set_visible(true)
			item_node.text = get_item_name(item) + " $" + str(get_product_price(item))
		amount += 1
		if amount == max_amount_vertically:
			var more_indicator = $MenuRight/Item.duplicate()
			more_indicator.text = "..."
			more_indicator.set_visible(true)
			more_indicator.position.y += 35 * amount
			$MenuRight.add_child(more_indicator)
	amount = 0
	for adquirance in adquirances:
		var item_node = $MenuLeft/Item.duplicate()
		item_node.visible = true
		item_node.position.y += 35 * amount
		item_node.text = get_item_name(adquirance.type) + " x" + str(adquirance.amount)
		var in_list_item = {
			'kind': adquirance.type,
			'amount': adquirance.amount,
			'node': item_node
		}
		menu_left_items.push_back(in_list_item)
		$MenuLeft.add_child(item_node)
		amount += 1

		
func buy_item(item):
	var price = get_product_price(item)
	if coin_available < price:
		salesman_talks(i18n_messages['NOT_ENOUGHT_COINS'])
		return; # TODO more coins needed
	coin_transfering = price
	salesman_talks(i18n_messages['THX'])
	match item:
		Adquirance.MUSHROOM:
			add_item_to_bag('mushroom', 1)
			return;
		Adquirance.MUSHROOM_5x:
			add_item_to_bag('mushroom', 5)
			return;
		Adquirance.RING:
			add_item_to_bag('ring', 1)
			return;
		Adquirance.RING_10x:
			add_item_to_bag('ring', 10)
			return;
		Adquirance.GREEN_MUSHROOM:
			add_item_to_bag('green_mushroom', 1)
			return;
		Adquirance.GREEN_MUSHROOM_5x:
			add_item_to_bag('green_mushroom', 5)
			return;
		Adquirance.GREEN_MUSHROOM_10x:
			add_item_to_bag('green_mushroom', 10)
			return;
		Adquirance.GREEN_MUSHROOM_20x:
			add_item_to_bag('green_mushroom', 20)
			return;
		Adquirance.LEAF:
			add_item_to_bag('leaf', 1)
			return;
		Adquirance.LEAF_5x:
			add_item_to_bag('leaf', 5)
			return;
		Adquirance.LEAF_10x:
			add_item_to_bag('leaf', 10)
			return;


func add_item_to_bag(type, amount):	
	for adquired in adquirances:
		if adquired.type == type:
			adquired.amount += amount
			rearrange_store()
			return;
	adquirances.push_back({ 'type': type, 'amount': amount })
	rearrange_store()


func salesman_talks(message):
	$SalesmanDialog/Label.text = message
	$SalesmanDialog.visible = true
	salesman_talking = 200
