module Mrg
  module Grid
    module Config
      module ArcUtils
        def modify_arcs(command,dests,options,getmsg,setmsg,explain="have an arc to")
          what ||= self.class.name.split("::").pop.downcase
          case command
          when "ADD" then 
            old_dests = Set[*self.send(getmsg)]
            new_dests = Set[*dests.keys]
            raise ArgumentError.new("#{what} #{name} cannot #{explain} itself") if new_dests.include? self.name
            self.send(setmsg, (old_dests + new_dests).to_a)
          when "REPLACE" then 
            new_dests = Set[*dests.keys]
            raise ArgumentError.new("#{what} #{name} cannot #{explain} itself") if new_dests.include? self.name
            self.send(setmsg, new_dests.to_a)
          when "UNION", "REMOVE", "INTERSECT", "DIFF" then
            raise RuntimeError.new("#{command} not implemented")            
          else nil
          end
        end
      end
    end
  end
end