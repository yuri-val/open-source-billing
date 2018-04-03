module Services
  class ImportQbPaymentService

    def import_data(options)
      counter = 0

      qbo_api = QboApi.new(access_token: options[:token], realm_id: options[:realm_id])
      if qbo_api.all(:payments).count > 0
        qbo_api.all(:payments) do |payment|
          begin
            if payment.present?
              unless ::Payment.find_by_provider_id(payment['Id'].to_i)
                if payment['Line'].present?
                  paid_full = payment['Line'][0]['LineEx']['any'][1]['value']['Value'].to_f == payment['Line'][0]['Amount'].to_f
                end
                hash = { provider: 'Quickbooks', provider_id: payment['Id'].to_i,
                         payment_date: (payment['TxnDate'] || payment['MetaData']['CreateTime']).to_date,
                         notes: payment['PrivateNote'],
                         paid_full: paid_full,
                         company_id: options[:current_company_id],
                         payment_method: (qbo_api.query(%{SELECT * FROM PaymentMethod WHERE Id = '#{payment['PaymentMethodRef']['value']}'}).first['Name'] if payment['PaymentMethodRef'].present?),
                         payment_amount: payment['TotalAmt'].to_f,
                         invoice_id: ::Invoice.find_by_provider_id(payment['Line'][0]['LinkedTxn'][0]['TxnId'].to_i).try(:id),
                         send_payment_notification: false # No param received
                         }
                osb_payment = ::Payment.new(hash)
                osb_payment.client = ::Client.find_by_provider_id(payment['CustomerRef']['value'].to_i) if payment['CustomerRef'].present? && payment['CustomerRef']['value'].present?
                osb_payment.save
              end
            end
          rescue Exception => e
            p e.inspect
          end
        end
      end
      "payment #{counter} record(s) successfully imported."
    end
  end
end