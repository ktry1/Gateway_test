import IcWebSocketCdk "mo:ic-websocket-cdk";
import IcWebSocketCdkState "mo:ic-websocket-cdk/State";
import IcWebSocketCdkTypes "mo:ic-websocket-cdk/Types";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Bool "mo:base/Bool";
import RBTree "mo:base/RBTree";
import Principal "mo:base/Principal";

actor Gateway {
  //Constants
  
  //Variables
  let connected_principals = RBTree.RBTree<IcWebSocketCdkTypes.ClientPrincipal, Bool>(Principal.compare);

  //Message types
  type AppMessage = {
    message : Text
  };

  //==============================
  //Functions of the canister
  //==============================
  
  func on_open(args : IcWebSocketCdk.OnOpenCallbackArgs) : async () {
    
  };

  func on_message(args : IcWebSocketCdk.OnMessageCallbackArgs) : async () {

  };

  func on_close(args : IcWebSocketCdk.OnCloseCallbackArgs) : async () {
    connected_principals.delete(args.client_principal)
  };

  //Callable functions

  public shared func send_message_to_clients(msg_bytes : Blob) : async IcWebSocketCdk.CanisterSendResult {
    var res : IcWebSocketCdk.CanisterSendResult = #Ok;

    label f for (entry in connected_principals.entries()) {
      switch (await IcWebSocketCdk.send(ws_state, entry.0, msg_bytes)) {
        case (#Ok(value)) {
          // Do nothing
        };
        case (#Err(error)) {
          res := #Err(error);
          break f
        }
      }
    };

    return res
  };

  //Handlers
  let params = IcWebSocketCdkTypes.WsInitParams(null, null);
  let ws_state = IcWebSocketCdkState.IcWebSocketState(params);

  let handlers = IcWebSocketCdkTypes.WsHandlers(
    ?on_open,
    ?on_message,
    ?on_close,
  );

  let ws = IcWebSocketCdk.IcWebSocket(ws_state, params, handlers);

  // method called by the WS Gateway after receiving FirstMessage from the client
  public shared ({ caller }) func ws_open(args : IcWebSocketCdk.CanisterWsOpenArguments) : async IcWebSocketCdk.CanisterWsOpenResult {
    await ws.ws_open(caller, args)
  };

  // method called by the Ws Gateway when closing the IcWebSocket connection
  public shared ({ caller }) func ws_close(args : IcWebSocketCdk.CanisterWsCloseArguments) : async IcWebSocketCdk.CanisterWsCloseResult {
    await ws.ws_close(caller, args)
  };

  // method called by the frontend SDK to send a message to the canister
  public shared ({ caller }) func ws_message(args : IcWebSocketCdk.CanisterWsMessageArguments, msg : ?AppMessage) : async IcWebSocketCdk.CanisterWsMessageResult {
    await ws.ws_message(caller, args, msg)
  };

  // method called by the WS Gateway to get messages for all the clients it serves
  public shared query ({ caller }) func ws_get_messages(args : IcWebSocketCdk.CanisterWsGetMessagesArguments) : async IcWebSocketCdk.CanisterWsGetMessagesResult {
    ws.ws_get_messages(caller, args)
  };

}
