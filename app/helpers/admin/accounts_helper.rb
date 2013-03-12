module Admin::AccountsHelper

  def country_form_column(record, input_name)
     country_select :record, :country, ['India', 'United States', 'United Kingdom'], {:include_blank => true}, :name => input_name
  end

  def level_form_column(record, input_name)
     select :record, :level, [['User', User::LEVEL_USER], ['CRM', User::LEVEL_CRM], ['Moderator', User::LEVEL_MODERATOR], ['Admin', User::LEVEL_ADMIN], ['Super Admin', User::LEVEL_SUPER_ADMIN]]
  end

  def status_form_column(record, input_name)
     select :record, :status, [['live', User::STATUS_LIVE], ['disabled', User::STATUS_DISABLED], ['activation pending', User::STATUS_ACTIVATION_PENDING]]
  end
end
