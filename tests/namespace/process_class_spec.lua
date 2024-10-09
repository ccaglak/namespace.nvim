-- local namespace = require("namespace.mainTest")
-- local stub = require("luassert.stub")

-- describe("mainTest", function()
--   describe("process_class_queue", function()
--     local queue, prefix, workspace_root, current_directory, callback

--     before_each(function()
--       queue = {
--         is_empty = stub.new(),
--         pop = stub.new(),
--       }
--       prefix = { { src = "src", prefix = "App\\" } }
--       workspace_root = "/home/user/project"
--       current_directory = "/home/user/project/src"
--       callback = stub.new()
--       stub(namespace, "process_single_class")
--     end)

--     after_each(function()
--       namespace.process_single_class:revert()
--     end)

--     it("should process empty queue", function()
--       queue.is_empty.returns(true)

--       namespace.process_class_queue(queue, prefix, workspace_root, current_directory, callback)

--       assert.stub(callback).was_called_with({})
--       assert.stub(namespace.process_single_class).was_not_called()
--     end)

--     it("should process single item in queue", function()
--       queue.is_empty.returns(false).returns(true)
--       queue.pop.returns({ name = "TestClass" })
--       namespace.process_single_class.invokes(function(_, _, _, _, cb)
--         cb("use App\\TestClass;")
--       end)

--       namespace.process_class_queue(queue, prefix, workspace_root, current_directory, callback)

--       assert.stub(callback).was_called_with({ "use App\\TestClass;" })
--       assert.stub(namespace.process_single_class).was_called(1)
--     end)

--     it("should process multiple items in queue", function()
--       queue.is_empty.returns(false).returns(false).returns(true)
--       queue.pop.returns({ name = "Class1" }).returns({ name = "Class2" })
--       namespace.process_single_class
--           .on_call_with({ name = "Class1" }, prefix, workspace_root, current_directory, match._)
--           .invokes(function(_, _, _, _, cb)
--             cb("use App\\Class1;")
--           end)
--       namespace.process_single_class
--           .on_call_with({ name = "Class2" }, prefix, workspace_root, current_directory, match._)
--           .invokes(function(_, _, _, _, cb)
--             cb("use App\\Class2;")
--           end)

--       namespace.process_class_queue(queue, prefix, workspace_root, current_directory, callback)

--       assert.stub(callback).was_called_with({ "use App\\Class1;", "use App\\Class2;" })
--       assert.stub(namespace.process_single_class).was_called(2)
--     end)

--     it("should handle null use statements", function()
--       queue.is_empty.returns(false).returns(false).returns(true)
--       queue.pop.returns({ name = "Class1" }).returns({ name = "Class2" })
--       namespace.process_single_class
--           .on_call_with({ name = "Class1" }, prefix, workspace_root, current_directory, match._)
--           .invokes(function(_, _, _, _, cb)
--             cb(nil)
--           end)
--       namespace.process_single_class
--           .on_call_with({ name = "Class2" }, prefix, workspace_root, current_directory, match._)
--           .invokes(function(_, _, _, _, cb)
--             cb("use App\\Class2;")
--           end)

--       namespace.process_class_queue(queue, prefix, workspace_root, current_directory, callback)

--       assert.stub(callback).was_called_with({ "use App\\Class2;" })
--       assert.stub(namespace.process_single_class).was_called(2)
--     end)
--   end)
-- end)
