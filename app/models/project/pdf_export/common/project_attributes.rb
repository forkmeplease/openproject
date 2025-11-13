# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Project::PDFExport::Common::ProjectAttributes
  EMPTY_VALUE_PLACEHOLDER = "–"

  def write_project_detail_content(project, export_fields)
    return if export_fields.empty?

    entries = []
    export_fields.each do |field|
      entries = process_field(project, field, entries)
    end
    write_table_entries(entries) unless entries.empty?
  end

  def process_field(project, field, entries)
    if custom_field?(field)
      process_custom_attribute_field(project, field, entries)
    elsif project_phase?(field)
      process_project_phase_field(project, field, entries)
    elsif can_view_attribute?(project, field[:key])
      process_attribute_field(project, field, entries)
    else
      entries
    end
  end

  def write_table_entries(row_entries)
    return if row_entries.empty?

    rows = if attributes_table_4_column?
             0.step(row_entries.length - 1, 2).map do |i|
               row_entries[i] + (row_entries[i + 1] || ["", ""])
             end
           else
             row_entries
           end

    pdf.table(
      rows,
      column_widths: attributes_table_column_widths,
      cell_style: styles.project_attributes_table_cell.merge({ inline_format: true })
    )
  end

  def process_project_phase_field(project, field, entries)
    entry = user_can_view_project_phases?(project) ? table_entry_project_phase(project, field) : nil
    entries.push(entry) if entry
    entries
  end

  def user_can_view_project_phases?(project)
    User.current.allowed_in_project?(:view_project_phases, project) && project.phases.active.any?
  end

  def table_entry_project_phase(project, field)
    project_phase_definition = Project::PhaseDefinition
                                 .find_by(id: field[:key][/\Aproject_phase_(\d+)\z/, 1])
    return nil if project_phase_definition.nil?

    phase = project.phases.active.find_by(definition: project_phase_definition)
    return nil if phase.nil?

    [
      { content: field[:caption] }.merge(styles.project_attributes_table_label_cell),
      format_phase_value(phase)
    ]
  end

  def format_phase_value(phase)
    start = if phase.start_date.present?
              format_date(phase.start_date)
            else
              I18n.t("js.label_no_start_date")
            end

    finish = if phase.finish_date.present?
               format_date(phase.finish_date)
             else
               I18n.t("js.label_no_due_date")
             end

    "#{start} - #{finish}"
  end

  def process_custom_attribute_field(project, field, entries)
    id = field[:key].to_s.sub("cf_", "").to_i
    custom_field = ProjectCustomField.find(id)
    return entries if custom_field.nil?
    return entries unless custom_field_active_in_project?(project, custom_field)

    if custom_field.formattable?
      write_table_entries(entries) unless entries.empty?
      write_formattable_custom_field(project, custom_field)
      []
    else
      entry = table_entry(project, field[:key], field[:caption])
      entries.push(entry) if entry
      entries
    end
  end

  def process_attribute_field(project, field, entries)
    if attribute_formattable?(field[:key])
      write_table_entries(entries) unless entries.empty?
      write_formattable_attribute(project, field[:key], field[:caption])
      []
    else
      entry = table_entry(project, field[:key], field[:caption])
      entries.push(entry) if entry
      entries
    end
  end

  def attribute_formattable?(attribute)
    %i[description status_explanation].include? attribute
  end

  def custom_field?(field)
    field[:key].to_s.start_with?("cf_")
  end

  def project_phase?(field)
    field[:key].to_s.start_with?("project_phase_")
  end

  def custom_field_active_in_project?(project, custom_field)
    custom_field.is_for_all? ||
      project.project_custom_field_project_mappings.exists?(custom_field_id: custom_field.id)
  end

  def write_project_markdown(project, value, caption)
    if value.blank?
      return if hide_empty_attributes?

      value = EMPTY_VALUE_PLACEHOLDER
    end
    write_markdown_label(caption)
    with_margin(styles.project_markdown_margins) do
      write_markdown!(
        apply_markdown_field_macros(value, { project:, user: User.current }),
        styles.project_markdown_styling_yml
      )
    end
  end

  def write_markdown_label(caption)
    with_margin(styles.project_markdown_label_margins) do
      pdf.formatted_text([styles.project_markdown_label.merge({ text: caption })])
    end
  end

  def attributes_table_4_column?
    false
  end

  def attributes_table_column_widths
    widths = if attributes_table_4_column?
               # label | value | label | value
               [1.5, 2.0, 1.5, 2.0]
             else
               # label | value
               [1.0, 3.0]
             end
    ratio = pdf.bounds.width / widths.sum
    widths.map { |w| w * ratio }
  end

  def table_entry(project, value_name, caption)
    value = format_attribute(project, value_name, :pdf)
    if value.blank?
      return nil if hide_empty_attributes?

      value = EMPTY_VALUE_PLACEHOLDER
    end

    if value.is_a?(::Exports::Formatters::LinkFormatter)
      value = get_cf_link_cell(value)
    elsif value_name == :id
      value = make_link_href_cell(url_helpers.project_url(project), value)
    end
    [
      { content: caption }.merge(styles.project_attributes_table_label_cell),
      value || ""
    ]
  end

  def write_formattable_attribute(project, attribute, caption)
    write_project_markdown project, project.try(attribute), caption
  end

  def write_formattable_custom_field(project, custom_field)
    custom_field_value = project.custom_value_for(custom_field)
    write_project_markdown project, custom_field_value.value, custom_field.name
  end
end
