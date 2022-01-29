class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :correct_user, only: [:edit_one_month, :update_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: :edit_one_month

  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"

  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: Time.current.change(sec: 0))
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current.change(sec: 0))
        flash[:info] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end

  # 勤怠編集
  def edit_one_month
    @attendance = Attendance.find(params[:id])
    @superior = User.where(superior: true).where.not(id: @user.id)
  end

  def update_one_month
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      edit_one_month_params.each do |id, item|
        if item[:instructor_confirmation].present? 
          if item[:edit_started_at].blank? || item[:edit_finished_at].blank?
            flash[:danger] = "時間を入力してください"
            redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return #上長が入ってなく、時間が入ってなかったら更新されません。and returnは繰り返しredirectが使われていること！
          end
          if item[:edit_started_at].present? && item[:edit_finished_at].present?
            if item[:edit_started_at] > item[:edit_finished_at]
              flash[:danger] = "出社時間より早い退社時間は無効です"
              redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return 
            end
          end
          item[:change_status] = "申請中"
          attendance = Attendance.find(id)
          attendance.attributes = item
          attendance.save!(context: :attendance_update)
          if item[:edit_finished_at].present?
             item[:edit_finished_at] = nil
          end
          if item[:instructor_confirmation].present?
             item[:instructor_confirmation] = nil
          end
          if item[:note].present?
             item[:note] = nil
          end
        end
      end
    end
    flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
  end
  
  # 残業申請のモーダル！
  def edit_overwork_request
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    @superior = User.where(superior: true).where.not(id: @user.id) #最初のwhereは上長A、上長B、where.notを付け加えることによって自分以外の上長! 
  end
  
  def update_overwork_request
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id]) #attendanceを更新！
    params[:attendance][:overtime_status] = "申請中" #[:attendance]の[overtime_status]が申請中だった場合
    if params[:attendance][:plan_finished_at].blank?
      flash[:danger] = "終了予定時間を入力してください"
      redirect_to user_url(@user)and return
    end
    if @attendance.update_attributes(overwork_params) #←ストロングパラメータの名前
      flash[:success] = "残業申請を更新しました"
      redirect_to user_url(@user)and return #処理で飛ばす先.com/rails/info/routesとホームページの方に書くとroute見れる
    else
      flash[:danger] = "残業申請を更新できませんでした。"
      redirect_to user_url(@user)and return #←user_urlの中に(@user)を入れることにより@userがuser_urlに飛ばされる！
    end
  end

  # 残業申請承認(お知らせ)モーダル！
  def edit_superior_announcement 
    @user = User.find(params[:user_id])
    @attendances = Attendance.where(overtime_status: "申請中", instructor_confirmation: @user.name).where.not(id: @user.id).order(:worked_on, :user_id).group_by(&:user_id)
    #@users = User.where(attendances:{overtime_status: "申請中"}).where.not(id: @user.id) #userひもづいてるattendanceモデルの中のovertime_statusの中の申請中のでーたを持ってるuserたちを持ってっ来る！
    #@users = User.joins(:attendances).group("users.id").where(attendances:{overtime_status: "申請中"}).where.not(id: @user.id) #joinsでattendancesのURLを持っているuserを集めてる！
  end
  
  def update_superior_announcement
    ActiveRecord::Base.transaction do
      @user = User.find(params[:user_id])
      n1 = 0
      n2 = 0
      n3 = 0
      n4 = 0
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        if item[:change] == "true"
          if item[:overtime_status] == "申請中" 
            n1 = n1 + 1
          elsif item[:overtime_status] == "承認" 
            n2 = n2 + 1
          elsif item[:overtime_status] == "否認" 
            n3 = n3 + 1
          elsif item[:overtime_status] == "なし" 
            n4 = n4 + 1
            attendance.note = nil
            attendance.instructor_confirmation = nil
            item[:change] = false 
            item[:overtime_status] = nil
          end
          attendance.update_attributes!(item)
        end
      end
      flash[:success] = "残業申請→申請中を#{n1}件、承認を#{n2}件、否認を#{n3}件、なしを#{n4}件送信しました"
      redirect_to user_url(@user) and return
    end
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to user_url(@user) and return
  end
  
  
  def new_show #勤怠申請モーダルの確認ボタン
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    @first_day = @attendance.worked_on.beginning_of_month #worked_on.日付、beginning_of_month月初日を計算してくれる。
    @last_day = @first_day.end_of_month #end_of_month���末日を計算してくれる。
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on) #order日付順に並び変える,..は～から～まで
    @worked_sum = @attendances.where.not(started_at: nil).count
  end
  
  # 勤怠変更更新モーダル
  def attendance_change
    @user = User.find(params[:user_id])
    @attendances = Attendance.where(change_status: "申請中", instructor_confirmation: @user.name).where.not(id: @user.id).order(:worked_on, :user_id).group_by(&:user_id)
  end
  
      
  def update_attendance_change
    ActiveRecord::Base.transaction do
      @user = User.find(params[:user_id])
        m1 = 0
        m2 = 0
        m3 = 0
        m4 = 0
       attendance_change_params.each do |id, item|
        attendance = Attendance.find(id)
        if item[:change] == "true"
          if item[:change_status] == "申請中"   
            m1 = m1 + 1
          elsif item[:change_status] == "承認"   
            m2 = m2 + 1
            attendance.good_day = Date.current #承認日
            # もしbefore_started_atがからだったら、before_started_atにstarted_atをいれてあげる。
            if attendance.before_started_at.blank?
              attendance.before_started_at = attendance.started_at #勤怠ログの開始時間になにも入っていなかったら,承認されたら、勤怠ログに入る設定！
            end  
            if attendance.before_finished_at.blank?
               attendance.before_finished_at = attendance.finished_at #勤怠ログの終了時間になにも入っていなかったら,承認されたら、勤怠ログに入る設定！
            end  
            attendance.started_at = attendance.edit_started_at
            attendance.finished_at = attendance.edit_finished_at #編集��たものが承認されshow.htmlの表に定義される設定
            if attendance.edit_started_at.present?
              attendance.edit_started_at = nil
            end  
              
          elsif item[:change_status] == "否認"   
            m3 = m3 + 1
          elsif item[:change_status] == "なし"   
            m4 = m4 + 1
            attendance.edit_started_at = nil
            attendance.edit_finished_at = nil
            attendance.note = nil
            attendance.instructor_confirmation = nil
            item[:change_status] = nil #ストロングパラメーターからきているためitemのchange_status 
            item[:change] = false 
          end
          attendance.update_attributes!(item)
        end
      end
      flash[:success] = "残業申請→申請中を#{m1}件、承認を#{m2}件、否認を#{m3}件、なしを#{m4}件送信しました"
      redirect_to user_url(@user) and return
    end
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to user_url(@user) and return
  end
  
  def new_show_change #確認ボタン
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    @first_day = @attendance.worked_on.beginning_of_month #worked_on.日付、beginning_of_month月初日を計算してくれる。
    @last_day = @first_day.end_of_month
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on) #order日付順に並び変える,..は～から～まで
    @worked_sum = @attendances.where.not(started_at: nil).count
  end
  
  def update_show #show.html.erb承認ボタン
    @user = User.find(params[:user_id]) #誰から申請きたか？
    if params[:user][:instructor_confirmation].present? #userはform_with 上長が指定されてるか？（空っぽの時の送られないように）
      attendance = @user.attendances.find_by(worked_on: params[:user][:first_day])
      #@userのattendanceのレコードを探すその中からfind_byの条件にあうもの@first_day(選択した月初日)を選ぶ項目
      attendance.user_one_month_attendance_status = "申請中" 
      #特定したレコードに対して申請中とuser_one_month_attendance_statusに入れてあげる
      attendance.update(user_attendance_show_params) #:attendance.updateで��新
      flash[:success] = "1ヶ月分の勤怠情報を申請しました。"
    end
    redirect_to user_url(@user)
  end
  
  # 所属長承認のモーダル
  def edit_superior_approval
    @user = User.find(params[:user_id])
    @attendances = Attendance.where(user_one_month_attendance_status: "申請中", instructor_confirmation: @user.name).where.not(id: @user.id).order(:worked_on, :user_id).group_by(&:user_id)
  end
  
  def update_superior_approval
     binding.pry
    ActiveRecord::Base.transaction do
      @user = User.find(params[:user_id])
        x1 = 0
        x2 = 0
        x3 = 0
        x4 = 0
      edit_superior_approval_params.each do |id, item|
        if item[:change] == "true"
          if item[:user_one_month_attendance_status] == "申請中" 
            x1 = x1 + 1
          elsif item[:user_one_month_attendance_status] == "承認" 
            x2 = x2 + 1
          elsif item[:user_one_month_attendance_status] == "否認" 
            x3 = x3 + 1
          elsif item[:user_one_month_attendance_status] == "なし" 
            x4 = x4 + 1
            attendance.note = nil
            attendance.instructor_confirmation = nil
            item[:change] = false 
            item[:user_one_month_attendance_status] = nil
          end  
          attendance = Attendance.find(id)  
          attendance.update_attributes!(item)
        end
      end
      flash[:success] = "残業申請→申請中を#{x1}件、承認を#{x2}件、否認を#{x3}件、なしを#{x4}件送信しました"
      redirect_to user_url(@user) and return
    end
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to user_url(@user) and return
  end
    
  
   private
   
    def overwork_params #残業申請ストロングパラメーター
       params.require(:attendance).permit(:plan_finished_at, :tomorrow, :business_processing_contents, :instructor_confirmation, :overtime_status) #この中のものを更新する！_edit_overwork_request.html.erbから更新」
    end
    # 残業申請のお知らせ
    def attendances_params
      params.require(:user).permit(attendances: [:change, :overtime_status])[:attendances] #この中の物は複数ある時に更新する [:attendances]はviewファイルで指定したところ
    end
    #require(:user)は中の(attendances: [:started_at, :finished_at, :note])[:attendances]のこと
    #require(:user)ない場合はパラメーターの中のものを探すだから第一改装しか見ない！updateできない
    
    def edit_one_month_params #edit_one_month（勤怠編集)のストロングパラメーター 
      params.require(:user).permit(attendances: [:edit_started_at, :edit_finished_at, :note, :instructor_confirmation, :change_status, :change])[:attendances] #この中の物は複数ある時に更新する [:attendances]はviewファイルで指定したところ
    end
    
    def user_attendance_show_params #一ヵ月分の勤怠申請承認ボタンから
      params.require(:user).permit(:instructor_confirmation)
    end
    
    def edit_superior_approval_params #所属長承認モーダル
      params.require(:user).permit(attendances: [:instructor_confirmation, :user_one_month_attendance_status, :change])[:attendances]
    end
    
    def attendance_change_params #変更申請ストロングパラメーター
      params.require(:user).permit(attendances: [:change_status, :change])[:attendances] #複数のための定義
    end
      
    def set_user
      @user = User.find(params[:id])
    end
  

    # ログイン済みのユーザーか確認します。
    def logged_in_user
      unless logged_in?
        store_location
        flash[:danger] = "ログインしてください。"
        redirect_to login_url
      end
    end

    # アクセスしたユーザーが現在ログインしているユーザーか確認します。
    def correct_user
      redirect_to(root_url) unless current_user?(@user)
    end

    
    def admin_user
      redirect_to (root_url) unless current_user.admin?
    end
    
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end  
    end
end