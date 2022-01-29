  Rails.application.routes.draw do
  

    root 'static_pages#top'
    get '/signup', to: 'users#new'
  
    # ログイン機能
    get    '/login', to: 'sessions#new'
    post   '/login', to: 'sessions#create'
    delete '/logout', to: 'sessions#destroy'
    
  
    resources :users do
      member do
        get 'edit_basic_info'
        patch 'update_basic_info'
        get 'attendances/edit_one_month'
        patch 'attendances/update_one_month'
        get 'working_employee_list'
        get 'base_list'
        get 'attendance_log' #勤怠ログ
       
      end
         
      resources :attendances, only: :update do #
        member do #idが付く！memberは特定のデータにアクションを利用する
          get 'edit_overwork_request'
          patch 'update_overwork_request'
           get 'new_show'
           get 'new_show_change'
        end
        collection do #idが付かない！collectionは全体のデータにアクションを利用する
          get 'edit_superior_announcement' #残業申請お知らせモーダル
          patch 'update_superior_announcement'
          get 'edit_superior_approval' #所属長承認モーダル
          patch 'update_superior_approval'
          get 'attendance_change' #勤怠変更申請モーダル
          patch 'update_attendance_change'
          patch 'update_show' #show,htmlの承認ボタン
        end  
      end
      
    end
    post '/import', to: 'users#import', as: 'import'
    
    resources :offices #拠点
      
                   
    
  end
    
      
      
    