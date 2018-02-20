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
    File.open('my_output.json', 'w') { |file| file.write(rentalPrice) }
  end
  
  private
  
  def rentalPrice
    @rentals.collect! { |rental| calculatePrice(rental) }
    JSON.pretty_generate({rentals: @rentals})
  end
  
  def calculatePrice(rental)
    durationPrice = durationPrice(rental)
    distancePrice = rental['distance'] * @cars[rental['car_id']]['price_per_km']
    {id: rental['id'], price: durationPrice + distancePrice}
  end

  def durationPrice(rental)
    price_per_day = @cars[rental['car_id']]['price_per_day']
    @duration = (Date.parse(rental['end_date']) - Date.parse(rental['start_date'])).to_i + 1
    durationPrice = 0
    (1..@duration).to_a.each_with_index{ |_, index|
      if index >= 10
        durationPrice += price_per_day * 0.5
      elsif index >= 4
        durationPrice += price_per_day * 0.7
      elsif index >= 1
        durationPrice += price_per_day * 0.9
      else
        durationPrice += price_per_day
      end
    }
    durationPrice.to_i
  end
end
