class UserUpgradesController < ApplicationController
  before_filter :member_only, :only => [:new, :show]
  helper_method :encrypt_custom, :coinbase

  def create
    user_id, level = decrypt_custom
    user = User.find(user_id)

    if user.level < User::Levels::PLATINUM && level >= User::Levels::Gold && level <= User::Levels::PLATINUM
      user.promote_to!(level, :skip_feedback => true)
    end

    flash[:success] = true
    redirect_to user_upgrade_path
  end

  def new
    unless CurrentUser.user.is_anonymous?
      TransactionLogItem.record_account_upgrade_view(CurrentUser.user, request.referer)
    end
  end

  def show
  end

  def encrypt_custom(level)
    crypt.encrypt_and_sign("#{CurrentUser.user.id},#{level}")
  end

  def coinbase
    @coinbase_api ||= Coinbase::Client.new(Danbooru.config.coinbase_api_key, Danbooru.config.coinbase_api_secret)
  end

  private

  def decrypt_custom
    crypt.decrypt_and_verify(params[:order][:custom]).split(/,/).map(&:to_i)
  end

  def crypt
    ActiveSupport::MessageEncryptor.new(Danbooru.config.coinbase_secret)
  end
end
