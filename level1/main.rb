require 'json'
require 'date'

class Main
  def initialize(data_file_name)
    data_file = File.open(data_file_name)
    data = JSON.parse(data_file.read)
    @cars = {}
    data['cars'].each do |car|
      @cars[car['id']] = car
    end
    @rentals = data['rentals']
  end
  
  def call
    rentalPrice
    File.open('my_output.json', 'w') { |file| file.write(@price) }
  end
  
  private
  
  def rentalPrice
    @rentals.collect! { |rental| calculatePrice(rental) }
    @price = JSON.pretty_generate({rentals: @rentals})
  end
  
  def calculateRentalPrice(rental)
    durationPrice = ((Date.parse(rental['end_date']) - Date.parse(rental['start_date'])).to_i + 1) * @cars[rental['car_id']]['price_per_day']
    distancePrice = rental['distance'] * @cars[rental['car_id']]['price_per_km']
    {id: rental['id'], price: durationPrice + distancePrice}
  end
  
end