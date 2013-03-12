require 'abimporter/abi'

class ContactsImporter
  def self.import(email_id, password, service)
    e = email_id.clone
    e << ".#{service}" unless service == 'email'
    Octazen::SimpleAddressBookImporter.fetch_contacts(e, password)
  end

end
