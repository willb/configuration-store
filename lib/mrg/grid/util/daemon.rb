# daemon.rb:  utilities for long-running processes
#
# Copyright (c) 2010 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Mrg
  module Grid
    module Util
      module Daemon
        def drop_privs(to_user=nil)
          to_user ||= "wallaby"
          if Process.euid == 0
            begin
              new_uid = Etc.getpwnam(to_user).uid
              new_gid = Etc.getpwnam(to_user).gid

              Process::Sys.setgid(new_gid)
              Process::Sys.setuid(new_uid)
            rescue ArgumentError
              Syslog.open do |s|
                s.warning "can't switch to user #{to_user}; does it exist?"
                puts  "can't switch to user #{to_user}; does it exist?"
              end
            end
          end
        end

        def daemonify
          pid = nil
          sid = nil

          return if Process.ppid == 1

          pid = fork

          if pid != nil
            if pid < 0
              Syslog.open {|s| s.fatal "can't fork child process"}
              exit!(1)
            end
            exit!(0)
          end

          sid = Process.setsid
          if sid < 0
            Syslog.open {|s| s.fatal "can't set self as session group leader"}
            exit!(1)
          end

          exit!(1) if Dir.chdir("/") < 0

          # close open FDs
          $stdin.reopen("/dev/null", "r")
          $stdout.reopen("/dev/null", "w")
          $stderr.reopen("/dev/null", "w")
        end
      end
    end
  end
end