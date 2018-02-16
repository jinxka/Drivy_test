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
  
  def calculatePrice(rental)
    durationPrice = getDurationPrice(rental)
    distancePrice = rental['distance'] * @cars[rental['car_id']]['price_per_km']
    {id: rental['id'], price: durationPrice + distancePrice}
  end
  
  def getDurationPrice(rental)
    price_per_day = @cars[rental['car_id']]['price_per_day']
    duration = (Date.parse(rental['end_date']) - Date.parse(rental['start_date'])).to_i + 1
    durationPrice = 0
    Array.new(duration).each_with_index do |_, index|
      case index
        when 0 .. 3
          durationPrice += price_per_day * 0.9
        when 4 .. 9
          durationPrice += price_per_day * 0.7
        when index > 10
          durationPrice += price_per_day * 0.5
        else
          durationPrice += price_per_day
      end
    end
    durationPrice.to_i
  end
end
