module Character::ParamsConcern
  extend ActiveSupport::Concern

  private

  def attr_name_or_map(attr_name, val)
    # RECURSION is used to map all hashes in params to update nested documents
    if val.is_a?(Hash)
      map = {} ; map[attr_name] = []

      if val.first[0] == "0"
        val.first[1].each { |arr_value_key, arr_value_value| map[attr_name] << attr_name_or_map(arr_value_key, arr_value_value) }
      else
        val.each { |hsh_key, hsh_value| map[attr_name] << attr_name_or_map(hsh_key, hsh_value) }
      end

      return map
    else
      return attr_name
    end
  end

  def permit_params(namespace='api')
    permit_fields = []
    params[namespace].each do |key, value|
      permit_fields << attr_name_or_map(key, value)
    end
    params.require(namespace).permit(permit_fields)
  end
end