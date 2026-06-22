# frozen_string_literal: true

module LdapDepartments
  module SynchronizedTrees
    class RowComponent < OpPrimer::BorderBoxRowComponent
      def name
        render(Primer::Beta::Link.new(
                 href: ldap_departments_synchronized_tree_path(tree_id: model.id),
                 font_weight: :bold
               )) { model.name }
      end

      def ldap_auth_source
        model.ldap_auth_source&.name
      end

      delegate :base_dn, to: :model

      def departments
        model.synchronized_departments.size
      end

      def button_links
        [edit_link, delete_link]
      end

      private

      def edit_link
        render(Primer::Beta::IconButton.new(
                 tag: :a,
                 icon: :pencil,
                 scheme: :invisible,
                 size: :small,
                 href: edit_ldap_departments_synchronized_tree_path(tree_id: model.id),
                 "aria-label": I18n.t(:button_edit)
               ))
      end

      def delete_link
        render(Primer::Beta::IconButton.new(
                 tag: :a,
                 icon: :trash,
                 scheme: :danger,
                 size: :small,
                 href: ldap_departments_synchronized_tree_path(tree_id: model.id),
                 "aria-label": I18n.t(:button_delete),
                 data: { turbo_method: :delete, turbo_confirm: I18n.t(:text_are_you_sure) }
               ))
      end
    end
  end
end
