# frozen_string_literal: true

module LdapDepartments
  class SynchronizedTreesController < ::ApplicationController
    include OpTurbo::ComponentStream

    before_action :require_admin

    guard_enterprise_feature(:ldap_groups, except: %i[index show deletion_dialog destroy]) do
      redirect_to action: :index, status: :see_other
    end

    before_action :find_tree, only: %i[show edit update destroy deletion_dialog synchronize]

    layout "admin"
    menu_item :plugin_ldap_departments

    def index
      @trees = SynchronizedTree.includes(:ldap_auth_source, :synchronized_departments)
    end

    def show
      @departments = @tree.synchronized_departments.includes(:group)
    end

    def new
      @tree = SynchronizedTree.new
    end

    def edit; end

    def create
      @tree = SynchronizedTree.new(permitted_params)

      if @tree.save
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to action: :show, tree_id: @tree.id
      else
        render action: :new, status: :unprocessable_entity
      end
    rescue ActionController::ParameterMissing
      render_400
    end

    def update
      if @tree.update(permitted_params)
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to action: :show
      else
        render action: :edit, status: :unprocessable_entity
      end
    rescue ActionController::ParameterMissing
      render_400
    end

    def deletion_dialog
      respond_with_dialog SynchronizedTrees::DeleteDialogComponent.new(tree: @tree)
    end

    def destroy
      if @tree.destroy
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = I18n.t(:error_can_not_delete_entry)
      end

      redirect_to action: :index, status: :see_other
    end

    def synchronize
      structure = SynchronizeTreeService.new(@tree).call
      members = SynchronizeMembersService.new(@tree).call

      set_synchronize_flash(structure, members)
      redirect_to action: :show
    end

    private

    def set_synchronize_flash(structure, members)
      if structure.success? && members.success?
        flash[:notice] = I18n.t("ldap_departments.label_n_departments_found", count: structure.result.to_i)
      else
        flash[:error] = [structure.message, members.message].compact.join(", ")
      end
    end

    def find_tree
      @tree = SynchronizedTree.find(params.expect(:tree_id))
    end

    def permitted_params
      params.expect(synchronized_tree: %i[name
                                          base_dn
                                          ldap_auth_source_id
                                          structure_filter_string
                                          ou_name_attribute
                                          guid_attribute
                                          user_filter_string
                                          sync_users])
    end
  end
end
