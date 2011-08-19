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
        
        [["overriding", "", "ALPHA"], ["appending", ">= ", "CHARLIE, BRAVO, ALPHA"]].each do |action, prefix, expected|
          it "should respect inter-group priorities when #{action}" do
            @store.addParam("LETTER")
            group_names = %w{Alpha Bravo Charlie}
            group_names.each {|g| @store.addExplicitGroup(g).modifyParams("ADD", {"LETTER"=>"#{prefix}#{g.upcase}"}, {})}
            fake = @store.addNode("fake")
            fake.modifyMemberships("ADD", group_names, {})
            @store.activateConfiguration

            fake.getConfig("version"=>fake.last_updated_version)["LETTER"].should == expected
          end

          it "should respect intra-group priorities when #{action}" do
            @store.addParam("LETTER")
            feature_names = %w{Alpha Bravo Charlie}
            feature_names.each {|f| @store.addFeature(f).modifyParams("ADD", {"LETTER"=>"#{prefix}#{f.upcase}"}, {})}
            fake = @store.addNode("fake")
            fake.identity_group.modifyFeatures("ADD", feature_names, {})
            @store.activateConfiguration

            fake.getConfig("version"=>fake.last_updated_version)["LETTER"].should == expected
          end
        end
      end
    end
  end
end
