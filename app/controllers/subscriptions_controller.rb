class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
      
  def index
    @account = Account.find_by(email: current_user.email)
  end
  
  def new
    @plans = Plan.all
  end
  
  def create
    
    # Get the credit card details submitted by the form
    token = params[:stripeToken]   
    plan = params[:plan][:stripe_id]
    email = current_user.email
    current_account = Account.find_by(email: current_user.email)
    customer_id = current_account.customer_id
    current_plan = current_account.stripe_plan_id
    
    if customer_id.nil?
      # Create a Customer
      @customer = Stripe::Customer.create(
        :source => token,
        :plan => plan,
        :email => email
      )
      subscriptions = @customer.subscriptions  
      @subscribed_plan =   subscriptions.data.find{ |o| o.plan.id == plan }
    else
      @customer = Stripe::Customer.retrieve(customer_id)
      @subscribed_plan = create_or_update_subscription(@customer, current_plan, plan)
    end

    
    #Get current period end - This is a unix timestamp
    current_period_end = @subscribed_plan.current_period_end
    #Convert to datetime
    active_until = Time.at(current_period_end).to_datetime  
    save_account_details(current_account, plan, @customer.id, active_until) 
      
    redirect_to :root, :notice => "Successfully subscribed to #{plan}"
    
  rescue => e
    redirect_to :back, :flash => { :error => e.message }

  end
  
  def save_account_details(account, plan, customer_id, active_until)
    # Customer created with valid subscription so update Account model
    account.stripe_plan_id = plan
    account.customer_id = customer_id
    account.active_until = active_until
    account.save!
  end
  
  def edit
    @account = Account.find(params[:id])
    @plans = Plan.all
  end
  
  def cancel_subscription
    email = current_user.email
    current_account = Account.find_by(email: current_user.email)
    customer_id = current_account.customer_id
    current_plan = current_account.stripe_plan_id
    
    if current_plan.blank?
      raise "No plan found to unsubscribe/cancel"
    end
    
    customer = Stripe::Customer.retrieve(customer_id)
    
    subscriptions = customer.subscriptions
    
    current_subscribed_plan = subscriptions.data.find { |o| o.plan.id == current_plan }
    
    if current_subscribed_plan.blank?
      raise "Subscription not found!"
    end
    
    current_subscribed_plan.delete
    
    save_account_details(current_account, "", customer_id, Time.at(0).to_datetime) 
    
    @message = "Subscription cancelled successfully"
    
  rescue => e
    redirect_to "/subscriptions", :flash => { :error => e.message}
  end
  
  
  
  def create_or_update_subscription(customer, current_plan, new_plan)
    subscriptions = customer.subscriptions
    current_subscription = subscriptions.data.find { |o| o.plan == current_plan }
    
    if current_subscription.blank?
      subscription = customer.subscriptions.create( { :plan => new_plan })
    else
      current_subscription.plan = new_plan
      subscription = current_subscription.save
    end
    subscription
  end
  
  def update_card
    
  end
  
  def update_card_details
    token = params[:stripeToken]   
    current_account = Account.find_by(email: current_user.email)
    customer_id = current_account.customer_id
     
    customer = Stripe::Customer.retrieve(customer_id)
    customer.source = token
    customer.save
    
    redirect_to "/subscriptions", :notice => "Card updated succesfully"
    
  rescue => e
    redirect_to :action => "update_card", :flash => { :error => e.message }   
  end
  
end
