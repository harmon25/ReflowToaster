defmodule ReflowController.Message do
    defstruct cmd_type: nil, resp_type: nil, msg_type: nil, src: nil, args: [], err: false, data: nil
end