require File.dirname(__FILE__) + '/lib/restful_permissions'

ActiveRecord::Base.send :include, RestfulPermissions::Permissions