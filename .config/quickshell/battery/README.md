# Battery popout system pieces

The caelestia battery popout (`caelestia/modules/bar/popouts/Battery.qml`,
`caelestia/services/BatteryInfo.qml`) depends on two things outside this repo.

## Charge-limit buttons: sudoers rule

`50-tlp-charge-limit` allows exactly the `tlp setcharge` calls the buttons make,
without a password. Keep it in sync with `chargePresets` in `BatteryInfo.qml`.

    sudo install -m 0440 -o root -g root 50-tlp-charge-limit /etc/sudoers.d/50-tlp-charge-limit

A click is temporary. `/etc/tlp.d/20-battery.conf` (75/80) is reapplied at boot.

## Power-profile buttons: tlp-pd

caelestia talks to `net.hadess.PowerProfiles`. With TLP, that has to be `tlp-pd`
(it provides `power-profiles-daemon`, so caelestia-shell's dependency stays met).
It's D-Bus activated, so `systemctl is-enabled` saying `disabled` is normal.

    sudo pacman -S tlp-pd    # removes power-profiles-daemon, which conflicts with TLP
