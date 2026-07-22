barrier = Product.find_or_create_by!(code: 'BAR-001') do |p|
  p.name = 'Heavy-Duty Barrier'
  p.base_price = 500.00
  p.category = 'Barriers'
end

color_group = OptionGroup.find_or_create_by!(product: barrier, name: 'Color')
OptionValue.find_or_create_by!(option_group: color_group, name: 'Yellow', price_modifier: 0.0)
OptionValue.find_or_create_by!(option_group: color_group, name: 'Red', price_modifier: 20.0)

length_group = OptionGroup.find_or_create_by!(product: barrier, name: 'Length')
OptionValue.find_or_create_by!(option_group: length_group, name: '1m', price_modifier: 0.0)
OptionValue.find_or_create_by!(option_group: length_group, name: '2m', price_modifier: 50.0)
OptionValue.find_or_create_by!(option_group: length_group, name: '3m', price_modifier: 100.0)

bollard = Product.find_or_create_by!(code: 'BOL-002') do |p|
  p.name = 'Steel Bollard'
  p.base_price = 150.00
  p.category = 'Bollards'
end

finish_group = OptionGroup.find_or_create_by!(product: bollard, name: 'Finish')
OptionValue.find_or_create_by!(option_group: finish_group, name: 'Galvanized', price_modifier: 0.0)
OptionValue.find_or_create_by!(option_group: finish_group, name: 'Powder Coated', price_modifier: 30.0)

height_group = OptionGroup.find_or_create_by!(product: bollard, name: 'Height')
OptionValue.find_or_create_by!(option_group: height_group, name: '1m', price_modifier: 0.0)
OptionValue.find_or_create_by!(option_group: height_group, name: '1.5m', price_modifier: 40.0)

rack_guard = Product.find_or_create_by!(code: 'RACK-003') do |p|
  p.name = 'Rack Guard'
  p.base_price = 200.00
  p.category = 'Rack Protectors'
end

material_group = OptionGroup.find_or_create_by!(product: rack_guard, name: 'Material')
OptionValue.find_or_create_by!(option_group: material_group, name: 'Steel', price_modifier: 0.0)
OptionValue.find_or_create_by!(option_group: material_group, name: 'Polymer', price_modifier: 15.0)

rack_color_group = OptionGroup.find_or_create_by!(product: rack_guard, name: 'Color')
OptionValue.find_or_create_by!(option_group: rack_color_group, name: 'Yellow', price_modifier: 0.0)
OptionValue.find_or_create_by!(option_group: rack_color_group, name: 'Grey', price_modifier: 5.0)

puts "Seeded #{Product.count} products, #{OptionGroup.count} option groups, #{OptionValue.count} option values."
