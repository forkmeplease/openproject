# frozen_string_literal: true

module LdapDepartments
  # Small helpers for working with LDAP distinguished names. Splitting is escape-aware so that
  # escaped commas (e.g. `cn=Doe\, John,ou=...`) do not break RDN boundaries.
  module Dn
    module_function

    def split_rdns(value)
      rdns = []
      current = +""
      escaped = false

      value.to_s.each_char do |char|
        if escaped
          current << char
          escaped = false
        elsif char == "\\"
          current << char
          escaped = true
        elsif char == ","
          rdns << current
          current = +""
        else
          current << char
        end
      end

      rdns << current
      rdns
    end

    # The parent container DN (everything past the first RDN), or nil for a single-component DN.
    def parent(value)
      rdns = split_rdns(value)
      return nil if rdns.size <= 1

      rdns.drop(1).join(",").strip
    end

    # Canonical form for case- and spacing-insensitive comparison.
    def normalize(value)
      split_rdns(value).map { |rdn| rdn.strip.downcase }.join(",")
    end
  end
end
