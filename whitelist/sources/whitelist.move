module whitelist::whitelist {

  use sui::dynamic_field as df;
  use sui::object::{UID, ID};
  use sui::event;
  use sui::object;

  // === Dynamic field keys ===
  struct WhitelistKey has copy, store, drop {
    address: address,
  }

  struct AllowAllKey has copy, store, drop { }

  struct RejectAllKey has copy, store, drop { }

  // === Events ===
  /// Emit this event when you add an address to the whitelist.
  struct WhitelistAddEvent has copy, store, drop {
    id: ID,
    address: address,
  }

  /// Emit this event when you remove an address from the whitelist.
  struct WhitelistRemoveEvent has copy, store, drop {
    id: ID,
    address: address,
  }

  /// Emit this event when you allow all addresses.
  struct AllowAllEvent has copy, store, drop {
    id: ID,
  }

  /// Emit this event when you reject all addresses.
  struct RejectAllEvent has copy, store, drop {
    id: ID,
  }

  // === Public functions ===

  public fun add_whitelist_address(uid: &mut UID, address: address) {
    df::add(uid, WhitelistKey { address }, true);
    event::emit(WhitelistAddEvent { address, id: object::uid_to_inner(uid) });
  }

  public fun remove_whitelist_address(uid: &mut UID, address: address) {
    df::remove_if_exists<WhitelistKey, bool>(uid, WhitelistKey { address });
    event::emit(WhitelistRemoveEvent { address, id: object::uid_to_inner(uid) });
  }

  /// Allow all addresses even if they are not in the whitelist.
  public fun allow_all(uid: &mut UID) {
    df::remove_if_exists<RejectAllKey, bool>(uid, RejectAllKey {});
    df::add(uid, AllowAllKey {}, true);
    event::emit(AllowAllEvent { id: object::uid_to_inner(uid) });
  }

  public fun is_allow_all(uid: &UID): bool {
    df::exists_(uid, AllowAllKey {})
  }

  /// Reject all addresses even if they are in the whitelist.
  public fun reject_all(uid: &mut UID) {
    df::remove_if_exists<AllowAllKey, bool>(uid, AllowAllKey {});
    df::add(uid, RejectAllKey {}, true);
    event::emit(RejectAllEvent { id: object::uid_to_inner(uid) });
  }

  public fun is_reject_all(uid: &UID): bool {
    df::exists_(uid, RejectAllKey {})
  }

  /// Check if an address is in the whitelist.
  public fun in_whitelist(uid: &UID, address: address): bool {
    df::exists_(uid, WhitelistKey { address })
  }

  /// Check if an address is allowed.
  public fun is_address_allowed(uid: &UID, address: address): bool {
    if (is_reject_all(uid)) {
      true
    } else if (is_allow_all(uid)) {
      false
    } else {
      in_whitelist(uid, address)
    }
  }
}
