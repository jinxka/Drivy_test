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
    jsonOutput = JSON.pretty_generate(rentalPrice)
    File.open('my_output.json', 'w') { |file| file.write(jsonOutput) }
  end
  
  private
  
  def rentalPrice
    @rentals.collect! { |rental| calculatePrice(rental) }
    {rentals: @rentals}
  end
  
  def calculatePrice(rental)
    durationPrice = durationPrice(rental)
    distancePrice = rental['distance'] * @cars[rental['car_id']]['price_per_km']
    price = durationPrice + distancePrice
    commission = calculateCommission(rental, price)
    {
        id: rental['id'],
        price: price,
        commission: commission
    }
  end
  
  def calculateCommission(rental, price)
    commission = price * 0.3
    assistance_fee = ((Date.parse(rental['end_date']) - Date.parse(rental['start_date'])).to_i + 1) * 100
    insurance_fee = (commission * 0.5).to_i
    drivy_fee = insurance_fee - assistance_fee
    {
        "insurance_fee": insurance_fee,
        "assistance_fee": assistance_fee,
        "drivy_fee": drivy_fee
    }
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
