# frozen_string_literal: true

module LdapDepartments
  module SynchronizedDepartments
    class RowComponent < OpPrimer::BorderBoxRowComponent
      def group
        return model.group&.name unless model.group

        render(Primer::Beta::Link.new(href: admin_department_path(model.group), font_weight: :bold)) { model.group.name }
      end

      delegate :dn, to: :model

      def users
        model.users_count
      end

      def button_links
        [delete_link]
      end

      private

      def delete_link
        render(Primer::Beta::IconButton.new(
                 tag: :a,
                 icon: :trash,
                 scheme: :danger,
                 size: :small,
                 href: ldap_departments_synchronized_department_path(department_id: model.id),
                 "aria-label": I18n.t(:button_delete),
                 data: { turbo_method: :delete, turbo_confirm: I18n.t(:text_are_you_sure) }
               ))
      end
    end
  end
end
