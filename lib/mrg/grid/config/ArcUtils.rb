module Mrg
  module Grid
    module Config
      module ArcUtils
        
        # * command is the "modify" command passed in from the tool
        # * dests is the set of keys for the input set
        # * options are provided by the tool
        # * getmsg is the message to get the current set of arcs
        # * setmsg is the message to set the current set of arcs
        # * keyword arguments include
        # ** =:explain= is a string describing the relationship modeled by the arc (for error messages)
        # ** =:keymsg= is the message to get the key value from self
        # ** =:preserve_order= is true if these arcs represent a list
        def modify_arcs(command,dests,options,getmsg,setmsg,kwargs=nil)
          # NB:  this must work for lists and sets; note the ADD/UNION case
          
          dests = dests.keys if dests.is_a? Hash
          
          kwargs ||= {}
          
          explain = kwargs[:explain] || "have an arc to"
          what = kwargs[:what] || self.class.name.split("::").pop.downcase
          keymsg = kwargs[:name] || :name
          preserve_order = kwargs[:preserve_order]
          
          case command.upcase
          when "ADD", "UNION" then 
            old_dests = preserve_order ? self.send(getmsg) : Set[*self.send(getmsg)]
            new_dests = preserve_order ? dests : Set[*dests]
            raise ArgumentError.new("#{what} #{name} cannot #{explain} itself") if new_dests.include? self.send(keymsg)
            self.send(setmsg, (old_dests + new_dests).to_a.uniq) # the uniq is important so this can work either as a list or set
          when "REPLACE" then 
            new_dests = Set[*dests]
            raise ArgumentError.new("#{what} #{name} cannot #{explain} itself") if new_dests.include? self.send(keymsg)
            self.send(setmsg, new_dests.to_a)
          when "REMOVE" then
            old_dests = self.send(getmsg)
            removed_dests = dests
            new_dests = old_dests - removed_dests
            self.send(setmsg, new_dests)
          when "INTERSECT", "DIFF" then
            raise RuntimeError.new("#{command} not implemented")            
          else nil
          end
        end
        
        def find_arcs(arc_class,label)
          arc_class.find_by(:source=>self, :label=>label).map do |arc|
            if block_given? 
              yield arc 
            else
              arc
            end
          end
        end
        
        def set_arcs(arc_class, label, dests, keyfindmsg, options=nil)
          options ||= {}
          klass = (options[:klass] or self.class)
          what = (options[:what] or klass.name.split("::").pop.downcase)
          dests = Set[*dests] unless options[:preserve_ordering]
          
          target_params = dests.map do |key|
            dest = klass.send(keyfindmsg, key)
            raise ArgumentError.new("#{key} is not a valid #{what} key") unless dest
            dest
          end
          
          arc_class.find_by(:source=>self, :label=>label).map {|p| p.delete }
          
          target_params.each do |dest|
            arc_class.create(:source=>self.row_id, :dest=>dest.row_id, :label=>label.row_id)
          end
          
          dests.to_a
        end
        
      end
    end
  end
end