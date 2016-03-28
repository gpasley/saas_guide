# Seeding Plan table

p1 = Stripe::Plan.retrieve("plan-basic")
p1 = Stripe::Plan.retrieve("plan-better")
p1 = Stripe::Plan.retrieve("plan-best")

Plan.create(:stripe_id => p1.id, :name => p1.name, :price => p1.amount, :interval => p1.interval)