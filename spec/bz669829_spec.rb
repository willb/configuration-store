require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'digest/md5'

module Mrg
  module Grid
    module Config

      describe Node do
        before(:each) do
          setup_rhubarb
          @store = Store.new
        end
        
        after(:each) do
          teardown_rhubarb
        end
        
        def first_dbtext
          open("#{File.dirname(__FILE__)}/bz669829_first.yaml", "r") {|db| db.read}
        end
        
        def second_dbtext
          open("#{File.dirname(__FILE__)}/bz669829_second.yaml", "r") {|db| db.read}
        end
        
        include BaseDBFixture
        
        {"first->second"=>[:first_dbtext, :second_dbtext], "second->first"=>[:second_dbtext,:first_dbtext]}.each do |order,msgs|
        
          it "should restart the master when DAEMON_LIST changes after a snapshot load and activate (#{order})" do
            reconstitute_db(self.send(msgs[0]))

            @store.activateConfiguration

            first_versions = Hash[*Node.find_all.inject([]) {|acc,n| acc << n.name; acc << n.last_updated_version}]

            reconstitute_db(self.send(msgs[1]))

            @store.activateConfiguration

            second_versions = Hash[*Node.find_all.inject([]) {|acc,n| acc << n.name; acc << n.last_updated_version}]

            Node.find_all.each do |n|
              fv = first_versions[n.name]
              sv = second_versions[n.name]

              # if the configuration changed at all for this node
              if fv && sv
                old_config = n.getConfig("version"=>fv)
                new_config = n.getConfig("version"=>sv)

                if old_config["DAEMON_LIST"] != new_config["DAEMON_LIST"]
                  params, restart, reconfig = n.whatChanged(fv,sv)
                  params.should include("DAEMON_LIST")
                  restart.should include("master")
                end

              end
            end
          end
        end
      end
    end
  end
end