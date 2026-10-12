# Steam Frame streaming on this PC: what was changed and why

Started 2026-10-11, against stutters and pauses in Beat Saber streamed from
the PC to the Steam Frame over its Wireless Adapter (28de:2432,
`rtw89_8852cu`), kernel 7.2.9-arch1-1, RX 9070 XT.

## What the logs showed

- vrlink "stream reset" storms (`Reset video stream because we had a stream
  reset request`, sometimes `ASSERT ... videovulkan.cpp:1685`) and FEC frame
  skips about every 3 s; ping to the Frame over the adapter jumped from 2 ms
  to 50-170 ms dozens of times a minute although the signal looked fine.
- When a storm lasts more than a second the Frame shows passthrough over the
  game and Beat Saber loses focus and pauses by itself.
- At 15:52 the adapter crashed (`rtw89_hw_scan_offload failed ret -110`, then
  USB disconnect, `device descriptor read error -110`) and stayed gone until
  16:39; meanwhile the stream silently went over the home router. That's the
  firmware crash on 2.4 GHz scans, fixed in kernel 7.3 (commit 355626a2,
  `RTW89_QUIRK_DISABLE_2GHZ`), probably not the USB extension cable.

The known issue: https://github.com/ValveSoftware/SteamVR-for-Linux/issues/965
(open). Per the reports there, on desktop Linux:
1. Steam can't turn on the adapter's low latency mode: the SteamOS helper
   script is missing (`~/.local/share/Steam/logs/*`: "No
   holo-realtek-firmware-toggles helper script found, low latency mode
   unavailable").
2. `rtw89` follows the Frame hotspot's VLP power class and transmits at
   ~4-7 dBm (Windows: 13-16 dBm), so the link retransmits constantly.
3. vrlink on Linux recovers badly from short stalls (only Valve can fix).

## Done

1. This package: Valve's own helper from the SteamOS sources
   (steamdeck-packages.steamos.cloud, holo-main, 1.3-3; the PKGBUILD checks the
   archive and Valve's file sums). Steam runs
   `/usr/bin/holo-polkit-helpers/holo-realtek-firmware-toggles
   set-low-latency-mode on` on connect: no power save, no firmware scans,
   A-MSDU off, HE-MCS 0-9, static -75 dBm packet detection, aggressive EDCA.
   Undone on disconnect/replug. Only change from Valve: the polkit action
   (root without password) is limited to the active local session
   (Valve allows any). Installed with `pacman -U` on 2026-10-11.
   pkgrel 4: with rtw89-steam-frame the adapter has no 2.4 GHz band, and
   `iw set bitrates` (the MCS 0-9 cap) always sends a 2.4 GHz mask, so the
   kernel answers EINVAL and Valve's script stopped there (Steam logged
   "Failed to set low latency mode on ... :245 ... :201"). The cap is now
   allowed to fail; everything else in low latency mode still applies.
   Check: `pkexec /usr/bin/holo-polkit-helpers/holo-realtek-firmware-toggles list`
   while connected (HW_SCAN and INACTIVE_PS should show X), and Steam's logs
   no longer say "No holo-realtek-firmware-toggles helper".
2. SteamVR settings (not a package): in
   `~/.local/share/Steam/config/steamvr.vrsettings`, section `driver_vrlink`,
   `"forceBaselineVideoFEC": true`. Backup of the original next to it:
   `steamvr.vrsettings.before-vrlink-fix.bak`. Edit only with SteamVR closed
   (it rewrites the file on exit). `allowMultipleLinks: false` was tried and
   removed the same day: the owner starts SteamVR before the Frame, the Frame
   reaches the PC over home Wi-Fi ~30 s before the adapter link is up, and
   with a single link the stream stayed on home Wi-Fi.

3. Package `../rtw89-steam-frame` (2026-10-11, after the adapter crashed
   again on the first connect with low latency mode in place): the rtw89
   driver from kernel.org 7.2.9 (signature checked), built for
   7.2.9-arch1-1 only, into `/usr/lib/modules/7.2.9-arch1-1/updates/`, with
   - upstream commit 355626a2 (Realtek, in 7.3): no 2.4 GHz band for
     28de:2432, so its firmware no longer scans where it crashes;
   - our opt-in `steam_frame_lpi` parameter: the adapter uses LPI instead of
     the VLP power limits (the TX power fix from #965, written here, limited
     to this adapter). Off by default; `/etc/modprobe.d/rtw89-steam-frame.conf`
     says how to turn it on.
   Check: `modinfo -n rtw89_core` points into `updates/rtw89-steam-frame/`,
   and `iw phy` for the adapter lists no 2.4 GHz band.
   On a kernel update the stock driver loads again (nothing breaks, the
   fixes are gone): bump `_kernver`/`_srcver`/`pkgver` and the archive sum
   (check kernel.org's .sign), rebuild. Drop 0001 from 7.3 on.

## Not done

4. Turning `steam_frame_lpi` on: next step. First session with 1-3 in place
   (2026-10-11 18:11-18:41, Beat Saber): no adapter crash, 16 stream resets in
   30 min, ~13 FEC frame skips/min on the Frame (was ~19), but ping spikes
   over the adapter unchanged (20-70/min > 20 ms) and one 1 s freeze (18:36:20)
   where nearly every video frame lost 6-106 packets PC -> Frame while ping
   stayed ~30 ms: loss in the adapter's transmit direction, which is what the
   VLP power cap affects. Try: `echo 1 | sudo tee
   /sys/module/rtw89_core/parameters/steam_frame_lpi`, reconnect the Frame
   (dmesg: "using LPI instead of VLP"), play with the logger, compare; if it
   helps, uncomment the line in `/etc/modprobe.d/rtw89-steam-frame.conf`.

## Results

- 2026-10-12 01:02-01:39, Beat Saber, LPI on at runtime (adapter at 13 dBm
  OFDM / 11 dBm MCS 160 MHz, was ~4): per minute on the Frame, frames with
  lost packets 13.7 -> 6.5, packets re-requested ~640 -> ~275; unrecoverable
  errors 9 -> 1, decoder stalls 4 -> 0; PC stream resets 16 -> 1 (startup
  only). Still felt as some lag; ping spikes over the adapter unchanged or
  more (~13/min > 50 ms). Persistent LPI: uncomment the line in
  `/etc/modprobe.d/rtw89-steam-frame.conf`.
- Next to try: Frame disconnected from home Wi-Fi while playing (its one
  radio serves 6 GHz ch 37 to the adapter and 5 GHz ch 48 at home, and with
  multi-link SteamVR also sends the stream over home Wi-Fi); then a lower
  bitrate.

## Undo

`sudo pacman -R holo-realtek-firmware-toggles rtw89-steam-frame` (then reboot); restore the `.bak` above
(SteamVR closed).
