# frozen_string_literal: true

Rails.application.routes.draw do
  namespace "ldap_departments" do
    resources :synchronized_trees,
              param: :tree_id do
      member do
        # Synchronize the organizational unit structure of a single tree
        get "synchronize"

        # Destroy warning
        get "destroy_info"
      end
    end

    resources :synchronized_departments,
              param: :department_id,
              only: %i(show destroy) do
      member do
        get "destroy_info"
      end
    end
  end
end
