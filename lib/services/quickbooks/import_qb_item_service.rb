module Services
  class ImportQbItemService

    def import_data(options)
      counter = 0
      entities = []

      qbo_api = QboApi.new(access_token: options[:token], realm_id: options[:realm_id])
      qbo_api.all(:items).each do |item|
        begin
          if item.present?
          unless ::Item.find_by_provider_id(item['Id'].to_i)
            hash = {  item_name: item['Name'],
                      item_description: item['Description'],
                      unit_cost: item['UnitPrice'].to_f,
                      created_at: Time.now, provider: 'Quickbooks',
                      provider_id: item['Id'].to_i,
                      quantity: item['QtyOnHand'].to_i}
            osb_item = ::Item.new (hash)
            osb_item.save
            counter += 1
            entities << {entity_id: osb_item.id, entity_type: 'Item', parent_id: options[:current_company_id], parent_type: 'Company'}
          end
          end
        rescue Exception => e
          p e.inspect
        end
      end
      ::CompanyEntity.create(entities)
      "Item #{counter} record(s) successfully imported."
    end
  end
end