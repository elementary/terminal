/*
* Copyright (c) 2020 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License version 3, as published by the Free Software Foundation.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

namespace Terminal {

    public class Themes {
        public const int PALETTE_SIZE = 19;
        public static Gee.ArrayList<Theme?> themes = new Gee.ArrayList<Theme?> ();

        // themes are taken from https://github.com/Mayccoll/Gogh
        // format is color01:color02:...:color16:background:foreground:cursor
        static construct {
            themes.add ({"Custom", ""});
            themes.add ({"Default (High Contrast)", "#073642:#dc322f:#859900:#b58900:#268bd2:#ec0048:#2aa198:#94a3a5:#586e75:#cb4b16:#859900:#b58900:#268bd2:#d33682:#2aa198:#6c71c4:#fff:#333:#839496"});
            themes.add ({"Default (Solarized Light)", "#073642:#dc322f:#859900:#b58900:#268bd2:#ec0048:#2aa198:#94a3a5:#586e75:#cb4b16:#859900:#b58900:#268bd2:#d33682:#2aa198:#6c71c4:rgba(253, 246, 227, 0.95):#586e75:#839496"});
            themes.add ({"Default (Dark)", "#073642:#dc322f:#859900:#b58900:#268bd2:#ec0048:#2aa198:#94a3a5:#586e75:#cb4b16:#859900:#b58900:#268bd2:#d33682:#2aa198:#6c71c4:rgba(46, 46, 46, 0.95):#a5a5a5:#839496"});
            themes.add ({"_base", "#292d3e:#f07178:#c3e88d:#ffcb6b:#82aaff:#c792ea:#60adec:#abb2bf:#959dcb:#f07178:#c3e88d:#ff5572:#82aaff:#ffcb6b:#676e95:#fffefe:#292d3e:#bfc7d5:#bfc7d5"});
            themes.add ({"3024 Day", "#090300:#db2d20:#01a252:#fded02:#01a0e4:#a16a94:#b5e4f4:#a5a2a2:#5c5855:#e8bbd0:#3a3432:#4a4543:#807d7c:#d6d5d4:#cdab53:#f7f7f7:#f7f7f7:#4a4543:#4a4543"});
            themes.add ({"3024 Night", "#090300:#db2d20:#01a252:#fded02:#01a0e4:#a16a94:#b5e4f4:#a5a2a2:#5c5855:#e8bbd0:#3a3432:#4a4543:#807d7c:#d6d5d4:#cdab53:#f7f7f7:#090300:#a5a2a2:#a5a2a2"});
            themes.add ({"Aci", "#363636:#ff0883:#83ff08:#ff8308:#0883ff:#8308ff:#08ff83:#b6b6b6:#424242:#ff1e8e:#8eff1e:#ff8e1e:#1e8eff:#8e1eff:#1eff8e:#c2c2c2:#0d1926:#b4e1fd:#b4e1fd"});
            themes.add ({"Aco", "#3f3f3f:#ff0883:#83ff08:#ff8308:#0883ff:#8308ff:#08ff83:#bebebe:#474747:#ff1e8e:#8eff1e:#ff8e1e:#1e8eff:#8e1eff:#1eff8e:#c4c4c4:#1f1305:#b4e1fd:#b4e1fd"});
            themes.add ({"Adventure Time", "#050404:#bd0013:#4ab118:#e7741e:#0f4ac6:#665993:#70a598:#f8dcc0:#4e7cbf:#fc5f5a:#9eff6e:#efc11a:#1997c6:#9b5953:#c8faf4:#f6f5fb:#1f1d45:#f8dcc0:#f8dcc0"});
            themes.add ({"Afterglow", "#151515:#a53c23:#7b9246:#d3a04d:#6c99bb:#9f4e85:#7dd6cf:#d0d0d0:#505050:#a53c23:#7b9246:#d3a04d:#547c99:#9f4e85:#7dd6cf:#f5f5f5:#222222:#d0d0d0:#d0d0d0"});
            themes.add ({"Alien Blood", "#112616:#7f2b27:#2f7e25:#717f24:#2f6a7f:#47587f:#327f77:#647d75:#3c4812:#e08009:#18e000:#bde000:#00aae0:#0058e0:#00e0c4:#73fa91:#0f1610:#637d75:#637d75"});
            themes.add ({"Argonaut", "#232323:#ff000f:#8ce10b:#ffb900:#008df8:#6d43a6:#00d8eb:#ffffff:#444444:#ff2740:#abe15b:#ffd242:#0092ff:#9a5feb:#67fff0:#ffffff:#0e1019:#fffaf4:#fffaf4"});
            themes.add ({"Arthur", "#3d352a:#cd5c5c:#86af80:#e8ae5b:#6495ed:#deb887:#b0c4de:#bbaa99:#554444:#cc5533:#88aa22:#ffa75d:#87ceeb:#996600:#b0c4de:#ddccbb:#1c1c1c:#ddeedd:#ddeedd"});
            themes.add ({"Atom", "#000000:#fd5ff1:#87c38a:#ffd7b1:#85befd:#b9b6fc:#85befd:#e0e0e0:#000000:#fd5ff1:#94fa36:#f5ffa8:#96cbfe:#b9b6fc:#85befd:#e0e0e0:#161719:#c5c8c6:#c5c8c6"});
            themes.add ({"Azu", "#000000:#ac6d74:#74ac6d:#aca46d:#6d74ac:#a46dac:#6daca4:#e6e6e6:#262626:#d6b8bc:#bcd6b8:#d6d3b8:#b8bcd6:#d3b8d6:#b8d6d3:#ffffff:#09111a:#d9e6f2:#d9e6f2"});
            themes.add ({"Belafonte Day", "#20111b:#be100e:#858162:#eaa549:#426a79:#97522c:#989a9c:#968c83:#5e5252:#be100e:#858162:#eaa549:#426a79:#97522c:#989a9c:#d5ccba:#d5ccba:#45373c:#45373c"});
            themes.add ({"Belafonte Night", "#20111b:#be100e:#858162:#eaa549:#426a79:#97522c:#989a9c:#968c83:#5e5252:#be100e:#858162:#eaa549:#426a79:#97522c:#989a9c:#d5ccba:#20111b:#968c83:#968c83"});
            themes.add ({"Bim", "#2c2423:#f557a0:#a9ee55:#f5a255:#5ea2ec:#a957ec:#5eeea0:#918988:#918988:#f579b2:#bbee78:#f5b378:#81b3ec:#bb79ec:#81eeb2:#f5eeec:#012849:#a9bed8:#a9bed8"});
            themes.add ({"Birds of Paradise", "#573d26:#be2d26:#6ba18a:#e99d2a:#5a86ad:#ac80a6:#74a6ad:#e0dbb7:#9b6c4a:#e84627:#95d8ba:#d0d150:#b8d3ed:#d19ecb:#93cfd7:#fff9d5:#2a1f1d:#e0dbb7:#e0dbb7"});
            themes.add ({"Blazer", "#000000:#b87a7a:#7ab87a:#b8b87a:#7a7ab8:#b87ab8:#7ab8b8:#d9d9d9:#262626:#dbbdbd:#bddbbd:#dbdbbd:#bdbddb:#dbbddb:#bddbdb:#ffffff:#0d1926:#d9e6f2:#d9e6f2"});
            themes.add ({"Bluloco Light", "#d5d6dd:#d52753:#23974a:#df631c:#275fe4:#823ff1:#27618d:#000000:#e4e5ed:#ff6480:#3cbc66:#c5a332:#0099e1:#ce33c0:#6d93bb:#26272d:#f9f9f9:#383a42:#383a42"});
            themes.add ({"Borland", "#4f4f4f:#ff6c60:#a8ff60:#ffffb6:#96cbfe:#ff73fd:#c6c5fe:#eeeeee:#7c7c7c:#ffb6b0:#ceffac:#ffffcc:#b5dcff:#ff9cfe:#dfdffe:#ffffff:#0000a4:#ffff4e:#ffff4e"});
            themes.add ({"Broadcast", "#000000:#da4939:#519f50:#ffd24a:#6d9cbe:#d0d0ff:#6e9cbe:#ffffff:#323232:#ff7b6b:#83d182:#ffff7c:#9fcef0:#ffffff:#a0cef0:#ffffff:#2b2b2b:#e6e1dc:#e6e1dc"});
            themes.add ({"Brogrammer", "#1f1f1f:#f81118:#2dc55e:#ecba0f:#2a84d2:#4e5ab7:#1081d6:#d6dbe5:#d6dbe5:#de352e:#1dd361:#f3bd09:#1081d6:#5350b9:#0f7ddb:#ffffff:#131313:#d6dbe5:#d6dbe5"});
            themes.add ({"C64", "#090300:#883932:#55a049:#bfce72:#40318d:#8b3f96:#67b6bd:#ffffff:#000000:#883932:#55a049:#bfce72:#40318d:#8b3f96:#67b6bd:#f7f7f7:#40318d:#7869c4:#7869c4"});
            themes.add ({"Cai", "#000000:#ca274d:#4dca27:#caa427:#274dca:#a427ca:#27caa4:#808080:#808080:#e98da3:#a3e98d:#e9d48d:#8da3e9:#d48de9:#8de9d4:#ffffff:#09111a:#d9e6f2:#d9e6f2"});
            themes.add ({"Chalk", "#646464:#f58e8e:#a9d3ab:#fed37e:#7aabd4:#d6add5:#79d4d5:#d4d4d4:#646464:#f58e8e:#a9d3ab:#fed37e:#7aabd4:#d6add5:#79d4d5:#d4d4d4:#2d2d2d:#d4d4d4:#d4d4d4"});
            themes.add ({"Chalkboard", "#000000:#c37372:#72c373:#c2c372:#7372c3:#c372c2:#72c2c3:#d9d9d9:#323232:#dbaaaa:#aadbaa:#dadbaa:#aaaadb:#dbaada:#aadadb:#ffffff:#29262f:#d9e6f2:#d9e6f2"});
            themes.add ({"Ciapre", "#181818:#810009:#48513b:#cc8b3f:#576d8c:#724d7c:#5c4f4b:#aea47f:#555555:#ac3835:#a6a75d:#dcdf7c:#3097c6:#d33061:#f3dbb2:#f4f4f4:#191c27:#aea47a:#aea47a"});
            themes.add ({"Clone of Ubuntu", "#2e3436:#cc0000:#4e9a06:#c4a000:#3465a4:#75507b:#06989a:#d3d7cf:#555753:#ef2929:#8ae234:#fce94f:#729fcf:#ad7fa8:#34e2e2:#eeeeec:#300a24:#ffffff:#ffffff"});
            themes.add ({"CLRS", "#000000:#f8282a:#328a5d:#fa701d:#135cd0:#9f00bd:#33c3c1:#b3b3b3:#555753:#fb0416:#2cc631:#fdd727:#1670ff:#e900b0:#3ad5ce:#eeeeec:#ffffff:#262626:#262626"});
            themes.add ({"Cobalt Neon", "#142631:#ff2320:#3ba5ff:#e9e75c:#8ff586:#781aa0:#8ff586:#ba46b2:#fff688:#d4312e:#8ff586:#e9f06d:#3c7dd2:#8230a7:#6cbc67:#8ff586:#142838:#8ff586:#8ff586"});
            themes.add ({"Cobalt 2", "#000000:#ff0000:#38de21:#ffe50a:#1460d2:#ff005d:#00bbbb:#bbbbbb:#555555:#f40e17:#3bd01d:#edc809:#5555ff:#ff55ff:#6ae3fa:#ffffff:#132738:#ffffff:#ffffff"});
            themes.add ({"Colorcli", "#000000:#d70000:#5faf00:#5faf00:#005f87:#d70000:#5f5f5f:#e4e4e4:#5f5f5f:#d70000:#5f5f5f:#ffff00:#0087af:#0087af:#0087af:#ffffff:#ffffff:#005f87:#005f87"});
            themes.add ({"Crayon Pony Fish", "#2b1b1d:#91002b:#579524:#ab311b:#8c87b0:#692f50:#e8a866:#68525a:#3d2b2e:#c5255d:#8dff57:#c8381d:#cfc9ff:#fc6cba:#ffceaf:#b0949d:#150707:#68525a:#68525a"});
            themes.add ({"Dark Pastel", "#000000:#ff5555:#55ff55:#ffff55:#5555ff:#ff55ff:#55ffff:#bbbbbb:#555555:#ff5555:#55ff55:#ffff55:#5555ff:#ff55ff:#55ffff:#ffffff:#000000:#ffffff:#ffffff"});
            themes.add ({"Darkside", "#000000:#e8341c:#68c256:#f2d42c:#1c98e8:#8e69c9:#1c98e8:#bababa:#000000:#e05a4f:#77b869:#efd64b:#387cd3:#957bbe:#3d97e2:#bababa:#222324:#bababa:#bababa"});
            themes.add ({"Desert", "#4d4d4d:#ff2b2b:#98fb98:#f0e68c:#cd853f:#ffdead:#ffa0a0:#f5deb3:#555555:#ff5555:#55ff55:#ffff55:#87ceff:#ff55ff:#ffd700:#ffffff:#333333:#ffffff:#ffffff"});
            themes.add ({"Dimmed Monokai", "#3a3d43:#be3f48:#879a3b:#c5a635:#4f76a1:#855c8d:#578fa4:#b9bcba:#888987:#fb001f:#0f722f:#c47033:#186de3:#fb0067:#2e706d:#fdffb9:#1f1f1f:#b9bcba:#b9bcba"});
            themes.add ({"Dracula", "#44475a:#ff5555:#50fa7b:#ffb86c:#8be9fd:#bd93f9:#ff79c6:#94a3a5:#000000:#ff5555:#50fa7b:#ffb86c:#8be9fd:#bd93f9:#ff79c6:#ffffff:#282a36:#94a3a5:#94a3a5"});
            themes.add ({"Earthsong", "#121418:#c94234:#85c54c:#f5ae2e:#1398b9:#d0633d:#509552:#e5c6aa:#675f54:#ff645a:#98e036:#e0d561:#5fdaff:#ff9269:#84f088:#f6f7ec:#292520:#e5c7a9:#e5c7a9"});
            themes.add ({"Elemental", "#3c3c30:#98290f:#479a43:#7f7111:#497f7d:#7f4e2f:#387f58:#807974:#555445:#e0502a:#61e070:#d69927:#79d9d9:#cd7c54:#59d599:#fff1e9:#22211d:#807a74:#807a74"});
            themes.add ({"Elementary", "#303030:#e1321a:#6ab017:#ffc005:#004f9e:#ec0048:#2aa7e7:#f2f2f2:#5d5d5d:#ff361e:#7bc91f:#ffd00a:#0071ff:#ff1d62:#4bb8fd:#a020f0:#101010:#f2f2f2:#f2f2f2"});
            themes.add ({"Elic", "#303030:#e1321a:#6ab017:#ffc005:#729fcf:#ec0048:#f2f2f2:#2aa7e7:#5d5d5d:#ff361e:#7bc91f:#ffd00a:#0071ff:#ff1d62:#4bb8fd:#a020f0:#4a453e:#f2f2f2:#f2f2f2"});
            themes.add ({"Elio", "#303030:#e1321a:#6ab017:#ffc005:#729fcf:#ec0048:#2aa7e7:#f2f2f2:#5d5d5d:#ff361e:#7bc91f:#ffd00a:#0071ff:#ff1d62:#4bb8fd:#a020f0:#041a3b:#f2f2f2:#f2f2f2"});
            themes.add ({"Espresso", "#353535:#d25252:#a5c261:#ffc66d:#6c99bb:#d197d9:#bed6ff:#eeeeec:#535353:#f00c0c:#c2e075:#e1e48b:#8ab7d9:#efb5f7:#dcf4ff:#ffffff:#323232:#ffffff:#ffffff"});
            themes.add ({"Espresso Libre", "#000000:#cc0000:#1a921c:#f0e53a:#0066ff:#c5656b:#06989a:#d3d7cf:#555753:#ef2929:#9aff87:#fffb5c:#43a8ed:#ff818a:#34e2e2:#eeeeec:#2a211c:#b8a898:#b8a898"});
            themes.add ({"Fairy Floss", "#42395d:#a8757b:#ff857f:#e6c000:#ae81ff:#716799:#c2ffdf:#f8f8f2:#75507b:#ffb8d1:#f1568e:#d5a425:#c5a3ff:#8077a8:#c2ffff:#f8f8f0:#5a5475:#c2ffdf:#ffb8d1"});
            themes.add ({"Fairy Floss Dark", "#42395d:#a8757b:#ff857f:#e6c000:#ae81ff:#716799:#c2ffdf:#f8f8f2:#75507b:#ffb8d1:#f1568e:#d5a425:#c5a3ff:#8077a8:#c2ffff:#f8f8f0:#42395d:#c2ffdf:#ffb8d1"});
            themes.add ({"Fishtank", "#03073c:#c6004a:#acf157:#fecd5e:#525fb8:#986f82:#968763:#ecf0fc:#6c5b30:#da4b8a:#dbffa9:#fee6a9:#b2befa:#fda5cd:#a5bd86:#f6ffec:#232537:#ecf0fe:#ecf0fe"});
            themes.add ({"Flat", "#2c3e50:#c0392b:#27ae60:#f39c12:#2980b9:#8e44ad:#16a085:#bdc3c7:#34495e:#e74c3c:#2ecc71:#f1c40f:#3498db:#9b59b6:#2aa198:#ecf0f1:#1f2d3a:#1abc9c:#1abc9c"});
            themes.add ({"Flat Remix", "#1f2229:#d41919:#5ebdab:#fea44c:#367bf0:#bf2e5d:#49aee6:#e6e6e6:#8c42ab:#ec0101:#47d4b9:#ff8a18:#277fff:#d71655:#05a1f7:#ffffff:#272a34:#ffffff:#ffffff"});
            themes.add ({"Flatland", "#1d1d19:#f18339:#9fd364:#f4ef6d:#5096be:#695abc:#d63865:#ffffff:#1d1d19:#d22a24:#a7d42c:#ff8949:#61b9d0:#695abc:#d63865:#ffffff:#1d1f21:#b8dbef:#b8dbef"});
            themes.add ({"Foxnightly", "#2a2a2e:#b98eff:#ff7de9:#729fcf:#66a05b:#75507b:#acacae:#ffffff:#a40000:#bf4040:#66a05b:#ffb86c:#729fcf:#8f5902:#c4a000:#5c3566:#2a2a2e:#d7d7db:#d7d7db"});
            themes.add ({"Freya", "#073642:#dc322f:#859900:#b58900:#268bd2:#ec0048:#2aa198:#94a3a5:#586e75:#cb4b16:#859900:#b58900:#268bd2:#d33682:#2aa198:#6c71c4:#252e32:#94a3a5:#839496"});
            themes.add ({"Frontend Delight", "#242526:#f8511b:#565747:#fa771d:#2c70b7:#f02e4f:#3ca1a6:#adadad:#5fac6d:#f74319:#74ec4c:#fdc325:#3393ca:#e75e4f:#4fbce6:#8c735b:#1b1c1d:#adadad:#adadad"});
            themes.add ({"Frontend Fun Forrest", "#000000:#d6262b:#919c00:#be8a13:#4699a3:#8d4331:#da8213:#ddc265:#7f6a55:#e55a1c:#bfc65a:#ffcb1b:#7cc9cf:#d26349:#e6a96b:#ffeaa3:#251200:#dec165:#dec165"});
            themes.add ({"Frontend Galaxy", "#000000:#f9555f:#21b089:#fef02a:#589df6:#944d95:#1f9ee7:#bbbbbb:#555555:#fa8c8f:#35bb9a:#ffff55:#589df6:#e75699:#3979bc:#ffffff:#1d2837:#ffffff:#ffffff"});
            themes.add ({"Geohot", "#f9f5f5:#cc0000:#1f1e1f:#ada110:#ff004e:#75507b:#06919a:#ffffff:#555753:#ef2929:#ff0000:#ada110:#5f4aa6:#b74438:#408f0c:#ffffff:#1f1e1f:#ffffff:#ffffff"});
            themes.add ({"GitHub", "#3e3e3e:#970b16:#07962a:#f8eec7:#003e8a:#e94691:#89d1ec:#ffffff:#666666:#de0000:#87d5a2:#f1d007:#2e6cba:#ffa29f:#1cfafe:#ffffff:#f4f4f4:#3e3e3e:#3e3e3e"});
            themes.add ({"Gooey", "#000009:#bb4f6c:#72ccae:#c65e3d:#58b6ca:#6488c4:#8d84c6:#858893:#1f222d:#ee829f:#a5ffe1:#f99170:#8be9fd:#97bbf7:#c0b7f9:#ffffff:#0d101b:#ebeef9:#ebeef9"});
            themes.add ({"Google Dark", "#1d1f21:#cc342b:#198844:#fba922:#3971ed:#a36ac7:#3971ed:#c5c8c6:#969896:#cc342b:#198844:#fba922:#3971ed:#a36ac7:#3971ed:#ffffff:#1d1f21:#b4b7b4:#b4b7b4"});
            themes.add ({"Google Light", "#ffffff:#cc342b:#198844:#fba921:#3870ed:#a26ac7:#3870ed:#373b41:#c5c8c6:#cc342b:#198844:#fba921:#3870ed:#a26ac7:#3870ed:#1d1f21:#ffffff:#373b41:#373b41"});
            themes.add ({"Gotham", "#0a0f14:#c33027:#26a98b:#edb54b:#195465:#4e5165:#33859d:#98d1ce:#10151b:#d26939:#081f2d:#245361:#093748:#888ba5:#599caa:#d3ebe9:#98d1ce:#0a0f14:#0a0f14"});
            themes.add ({"Grape", "#2d283f:#ed2261:#1fa91b:#8ddc20:#487df4:#8d35c9:#3bdeed:#9e9ea0:#59516a:#f0729a:#53aa5e:#b2dc87:#a9bcec:#ad81c2:#9de3eb:#a288f7:#171423:#9f9fa1:#9f9fa1"});
            themes.add ({"Grass", "#000000:#bb0000:#00bb00:#e7b000:#0000a3:#950062:#00bbbb:#bbbbbb:#555555:#bb0000:#00bb00:#e7b000:#0000bb:#ff55ff:#55ffff:#ffffff:#13773d:#fff0a5:#fff0a5"});
            themes.add ({"Gruvbox", "#fbf1c7:#cc241d:#98971a:#d79921:#458588:#b16286:#689d6a:#7c6f64:#928374:#9d0006:#79740e:#b57614:#076678:#8f3f71:#427b58:#3c3836:#fbf1c7:#3c3836:#3c3836"});
            themes.add ({"Gruvbox Dark", "#282828:#cc241d:#98971a:#d79921:#458588:#b16286:#689d6a:#a89984:#928374:#fb4934:#b8bb26:#fabd2f:#83a598:#d3869b:#8ec07c:#ebdbb2:#282828:#ebdbb2:#ebdbb2"});
            themes.add ({"hardcore", "#1b1d1e:#f92672:#a6e22e:#fd971f:#66d9ef:#9e6ffe:#5e7175:#ccccc6:#505354:#ff669d:#beed5f:#e6db74:#66d9ef:#9e6ffe:#a3babf:#f8f8f2:#121212:#a0a0a0:#a0a0a0"});
            themes.add ({"harper", "#010101:#f8b63f:#7fb5e1:#d6da25:#489e48:#b296c6:#f5bfd7:#a8a49d:#726e6a:#f8b63f:#7fb5e1:#d6da25:#489e48:#b296c6:#f5bfd7:#fefbea:#010101:#a8a49d:#a8a49d"});
            themes.add ({"Hemisu Dark", "#444444:#ff0054:#b1d630:#9d895e:#67bee3:#b576bc:#569a9f:#ededed:#777777:#d65e75:#baffaa:#ece1c8:#9fd3e5:#deb3df:#b6e0e5:#ffffff:#000000:#ffffff:#baffaa"});
            themes.add ({"Hemisu Light", "#777777:#ff0055:#739100:#503d15:#538091:#5b345e:#538091:#999999:#999999:#d65e76:#9cc700:#947555:#9db3cd:#a184a4:#85b2aa:#bababa:#efefef:#444444:#ff0054"});
            themes.add ({"Highway", "#000000:#d00e18:#138034:#ffcb3e:#006bb3:#6b2775:#384564:#ededed:#5d504a:#f07e18:#b1d130:#fff120:#4fc2fd:#de0071:#5d504a:#ffffff:#222225:#ededed:#ededed"});
            themes.add ({"Hipster Green", "#000000:#b6214a:#00a600:#bfbf00:#246eb2:#b200b2:#00a6b2:#bfbfbf:#666666:#e50000:#86a93e:#e5e500:#0000ff:#e500e5:#00e5e5:#e5e5e5:#100b05:#84c138:#84c138"});
            themes.add ({"Homebrew", "#000000:#990000:#00a600:#999900:#0000b2:#b200b2:#00a6b2:#bfbfbf:#666666:#e50000:#00d900:#e5e500:#0000ff:#e500e5:#00e5e5:#e5e5e5:#000000:#00ff00:#00ff00"});
            themes.add ({"Hurtado", "#575757:#ff1b00:#a5e055:#fbe74a:#496487:#fd5ff1:#86e9fe:#cbcccb:#262626:#d51d00:#a5df55:#fbe84a:#89beff:#c001c1:#86eafe:#dbdbdb:#000000:#dbdbdb:#dbdbdb"});
            themes.add ({"Hybrid", "#282a2e:#a54242:#8c9440:#de935f:#5f819d:#85678f:#5e8d87:#969896:#373b41:#cc6666:#b5bd68:#f0c674:#81a2be:#b294bb:#8abeb7:#c5c8c6:#141414:#94a3a5:#94a3a5"});
            themes.add ({"ibm3270", "#222222:#f01818:#24d830:#f0d824:#7890f0:#f078d8:#54e4e4:#a5a5a5:#888888:#ef8383:#7ed684:#efe28b:#b3bfef:#efb3e3:#9ce2e2:#ffffff:#000000:#fdfdfd:#fdfdfd"});
            themes.add ({"IC Green PPL", "#1f1f1f:#fb002a:#339c24:#659b25:#149b45:#53b82c:#2cb868:#e0ffef:#032710:#a7ff3f:#9fff6d:#d2ff6d:#72ffb5:#50ff3e:#22ff71:#daefd0:#3a3d3f:#d9efd3:#d9efd3"});
            themes.add ({"IC Orange PPL", "#000000:#c13900:#a4a900:#caaf00:#bd6d00:#fc5e00:#f79500:#ffc88a:#6a4f2a:#ff8c68:#f6ff40:#ffe36e:#ffbe55:#fc874f:#c69752:#fafaff:#262626:#ffcb83:#ffcb83"});
            themes.add ({"Idle Toes", "#323232:#d25252:#7fe173:#ffc66d:#4099ff:#f680ff:#bed6ff:#eeeeec:#535353:#f07070:#9dff91:#ffe48b:#5eb7f7:#ff9dff:#dcf4ff:#ffffff:#323232:#ffffff:#ffffff"});
            themes.add ({"Ir Black", "#4e4e4e:#ff6c60:#a8ff60:#ffffb6:#69cbfe:#ff73fd:#c6c5fe:#eeeeee:#7c7c7c:#ffb6b0:#ceffac:#ffffcb:#b5dcfe:#ff9cfe:#dfdffe:#ffffff:#000000:#eeeeee:#ffa560"});
            themes.add ({"Jackie Brown", "#2c1d16:#ef5734:#2baf2b:#bebf00:#246eb2:#d05ec1:#00acee:#bfbfbf:#666666:#e50000:#86a93e:#e5e500:#0000ff:#e500e5:#00e5e5:#e5e5e5:#2c1d16:#ffcc2f:#ffcc2f"});
            themes.add ({"Japanesque", "#343935:#cf3f61:#7bb75b:#e9b32a:#4c9ad4:#a57fc4:#389aad:#fafaf6:#595b59:#d18fa6:#767f2c:#78592f:#135979:#604291:#76bbca:#b2b5ae:#1e1e1e:#f7f6ec:#f7f6ec"});
            themes.add ({"Jellybeans", "#929292:#e27373:#94b979:#ffba7b:#97bedc:#e1c0fa:#00988e:#dedede:#bdbdbd:#ffa1a1:#bddeab:#ffdca0:#b1d8f6:#fbdaff:#1ab2a8:#ffffff:#121212:#dedede:#dedede"});
            themes.add ({"Jup", "#000000:#dd006f:#6fdd00:#dd6f00:#006fdd:#6f00dd:#00dd6f:#f2f2f2:#7d7d7d:#ff74b9:#b9ff74:#ffb974:#74b9ff:#b974ff:#74ffb9:#ffffff:#758480:#23476a:#23476a"});
            themes.add ({"Kibble", "#4d4d4d:#c70031:#29cf13:#d8e30e:#3449d1:#8400ff:#0798ab:#e2d1e3:#5a5a5a:#f01578:#6ce05c:#f3f79e:#97a4f7:#c495f0:#68f2e0:#ffffff:#0e100a:#f7f7f7:#f7f7f7"});
            themes.add ({"kokuban", "#2e8744:#d84e4c:#95da5a:#d6e264:#4b9ed7:#945fc5:#d89b25:#d8e2d7:#34934f:#ff4f59:#aff56a:#fcff75:#57aeff:#ae63e9:#ffaa2b:#fffefe:#0d4a08:#d8e2d7:#d8e2d7"});
            themes.add ({"Later This Evening", "#2b2b2b:#d45a60:#afba67:#e5d289:#a0bad6:#c092d6:#91bfb7:#3c3d3d:#454747:#d3232f:#aabb39:#e5be39:#6699d6:#ab53d6:#5fc0ae:#c1c2c2:#222222:#959595:#959595"});
            themes.add ({"Lavandula", "#230046:#7d1625:#337e6f:#7f6f49:#4f4a7f:#5a3f7f:#58777f:#736e7d:#372d46:#e05167:#52e0c4:#e0c386:#8e87e0:#a776e0:#9ad4e0:#8c91fa:#050014:#736e7d:#736e7d"});
            themes.add ({"Liquid Carbon", "#000000:#ff3030:#559a70:#ccac00:#0099cc:#cc69c8:#7ac4cc:#bccccc:#000000:#ff3030:#559a70:#ccac00:#0099cc:#cc69c8:#7ac4cc:#bccccc:#303030:#afc2c2:#afc2c2"});
            themes.add ({"Liquid Carbon Transparent", "#000000:#ff3030:#559a70:#ccac00:#0099cc:#cc69c8:#7ac4cc:#bccccc:#000000:#ff3030:#559a70:#ccac00:#0099cc:#cc69c8:#7ac4cc:#bccccc:#000000:#afc2c2:#afc2c2"});
            themes.add ({"Maia", "#232423:#ba2922:#7e807e:#4c4f4d:#16a085:#43746a:#00cccc:#e0e0e0:#282928:#cc372c:#8d8f8d:#4e524f:#13bf9d:#487d72:#00d1d1:#e8e8e8:#31363b:#bdc3c7:#bdc3c7"});
            themes.add ({"Man Page", "#000000:#cc0000:#00a600:#999900:#0000b2:#b200b2:#00a6b2:#cccccc:#666666:#e50000:#00d900:#e5e500:#0000ff:#e500e5:#00e5e5:#e5e5e5:#fef49c:#000000:#000000"});
            themes.add ({"Mar", "#000000:#b5407b:#7bb540:#b57b40:#407bb5:#7b40b5:#40b57b:#f8f8f8:#737373:#cd73a0:#a0cd73:#cda073:#73a0cd:#a073cd:#73cda0:#ffffff:#ffffff:#23476a:#23476a"});
            themes.add ({"Material", "#073641:#eb606b:#c3e88d:#f7eb95:#80cbc3:#ff2490:#aeddff:#ffffff:#002b36:#eb606b:#c3e88d:#f7eb95:#7dc6bf:#6c71c3:#34434d:#ffffff:#1e282c:#c3c7d1:#657b83"});
            themes.add ({"Mathias", "#000000:#e52222:#a6e32d:#fc951e:#c48dff:#fa2573:#67d9f0:#f2f2f2:#555555:#ff5555:#55ff55:#ffff55:#5555ff:#ff55ff:#55ffff:#ffffff:#000000:#bbbbbb:#bbbbbb"});
            themes.add ({"Medallion", "#000000:#b64c00:#7c8b16:#d3bd26:#616bb0:#8c5a90:#916c25:#cac29a:#5e5219:#ff9149:#b2ca3b:#ffe54a:#acb8ff:#ffa0ff:#ffbc51:#fed698:#1d1908:#cac296:#cac296"});
            themes.add ({"Misterioso", "#000000:#ff4242:#74af68:#ffad29:#338f86:#9414e6:#23d7d7:#e1e1e0:#555555:#ff3242:#74cd68:#ffb929:#23d7d7:#ff37ff:#00ede1:#ffffff:#2d3743:#e1e1e0:#e1e1e0"});
            themes.add ({"Miu", "#000000:#b87a7a:#7ab87a:#b8b87a:#7a7ab8:#b87ab8:#7ab8b8:#d9d9d9:#262626:#dbbdbd:#bddbbd:#dbdbbd:#bdbddb:#dbbddb:#bddbdb:#ffffff:#0d1926:#d9e6f2:#d9e6f2"});
            themes.add ({"Molokai", "#1b1d1e:#7325fa:#23e298:#60d4df:#d08010:#ff0087:#d0a843:#bbbbbb:#555555:#9d66f6:#5fe0b1:#6df2ff:#ffaf00:#ff87af:#ffce51:#ffffff:#1b1d1e:#bbbbbb:#bbbbbb"});
            themes.add ({"Mona Lisa", "#351b0e:#9b291c:#636232:#c36e28:#515c5d:#9b1d29:#588056:#f7d75c:#874228:#ff4331:#b4b264:#ff9566:#9eb2b4:#ff5b6a:#8acd8f:#ffe598:#120b0d:#f7d66a:#f7d66a"});
            themes.add ({"mono-amber", "#402500:#ff9400:#ff9400:#ff9400:#ff9400:#ff9400:#ff9400:#ff9400:#ff9400:#ff9400:#ff9400:#ff9400:#ff9400:#ff9400:#ff9400:#ff9400:#2b1900:#ff9400:#ff9400"});
            themes.add ({"mono-cyan", "#003340:#00ccff:#00ccff:#00ccff:#00ccff:#00ccff:#00ccff:#00ccff:#00ccff:#00ccff:#00ccff:#00ccff:#00ccff:#00ccff:#00ccff:#00ccff:#00222b:#00ccff:#00ccff"});
            themes.add ({"mono-green", "#034000:#0bff00:#0bff00:#0bff00:#0bff00:#0bff00:#0bff00:#0bff00:#0bff00:#0bff00:#0bff00:#0bff00:#0bff00:#0bff00:#0bff00:#0bff00:#022b00:#0bff00:#0bff00"});
            themes.add ({"mono-red", "#401200:#ff3600:#ff3600:#ff3600:#ff3600:#ff3600:#ff3600:#ff3600:#ff3600:#ff3600:#ff3600:#ff3600:#ff3600:#ff3600:#ff3600:#ff3600:#2b0c00:#ff3600:#ff3600"});
            themes.add ({"mono-white", "#3b3b3b:#fafafa:#fafafa:#fafafa:#fafafa:#fafafa:#fafafa:#fafafa:#fafafa:#fafafa:#fafafa:#fafafa:#fafafa:#fafafa:#fafafa:#fafafa:#262626:#fafafa:#fafafa"});
            themes.add ({"mono-yellow", "#403500:#ffd300:#ffd300:#ffd300:#ffd300:#ffd300:#ffd300:#ffd300:#ffd300:#ffd300:#ffd300:#ffd300:#ffd300:#ffd300:#ffd300:#ffd300:#2b2400:#ffd300:#ffd300"});
            themes.add ({"Monokai Dark", "#75715e:#f92672:#a6e22e:#f4bf75:#66d9ef:#ae81ff:#2aa198:#f9f8f5:#272822:#f92672:#a6e22e:#f4bf75:#66d9ef:#ae81ff:#2aa198:#f8f8f2:#272822:#f8f8f2:#f8f8f2"});
            themes.add ({"Monokai Soda", "#1a1a1a:#f4005f:#98e024:#fa8419:#9d65ff:#f4005f:#58d1eb:#c4c5b5:#625e4c:#f4005f:#98e024:#e0d561:#9d65ff:#f4005f:#58d1eb:#f6f6ef:#1a1a1a:#c4c5b5:#c4c5b5"});
            themes.add ({"N0tch2k", "#383838:#a95551:#666666:#a98051:#657d3e:#767676:#c9c9c9:#d0b8a3:#474747:#a97775:#8c8c8c:#a99175:#98bd5e:#a3a3a3:#dcdcdc:#d8c8bb:#222222:#a0a0a0:#a0a0a0"});
            themes.add ({"neon-night", "#20242d:#ff8e8e:#7efdd0:#fcad3f:#69b4f9:#dd92f6:#8ce8ff:#c9cccd:#20242d:#ff8e8e:#7efdd0:#fcad3f:#69b4f9:#dd92f6:#8ce8ff:#c9cccd:#20242d:#c7c8ff:#c7c8ff"});
            themes.add ({"Neopolitan", "#000000:#800000:#61ce3c:#fbde2d:#253b76:#ff0080:#8da6ce:#f8f8f8:#000000:#800000:#61ce3c:#fbde2d:#253b76:#ff0080:#8da6ce:#f8f8f8:#271f19:#ffffff:#ffffff"});
            themes.add ({"Nep", "#000000:#dd6f00:#00dd6f:#6fdd00:#6f00dd:#dd006f:#006fdd:#f2f2f2:#7d7d7d:#ffb974:#74ffb9:#b9ff74:#b974ff:#ff74b9:#74b9ff:#ffffff:#758480:#23476a:#23476a"});
            themes.add ({"Neutron", "#23252b:#b54036:#5ab977:#deb566:#6a7c93:#a4799d:#3f94a8:#e6e8ef:#23252b:#b54036:#5ab977:#deb566:#6a7c93:#a4799d:#3f94a8:#ebedf2:#1c1e22:#e6e8ef:#e6e8ef"});
            themes.add ({"Night Owl", "#011627:#ef5350:#22da6e:#addb67:#82aaff:#c792ea:#21c7a8:#ffffff:#575656:#ef5350:#22da6e:#ffeb95:#82aaff:#c792ea:#7fdbca:#ffffff:#011627:#d6deeb:#d6deeb"});
            themes.add ({"Nightlion V1", "#4c4c4c:#bb0000:#5fde8f:#f3f167:#276bd8:#bb00bb:#00dadf:#bbbbbb:#555555:#ff5555:#55ff55:#ffff55:#5555ff:#ff55ff:#55ffff:#ffffff:#000000:#bbbbbb:#bbbbbb"});
            themes.add ({"Nightlion V2", "#4c4c4c:#bb0000:#04f623:#f3f167:#64d0f0:#ce6fdb:#00dadf:#bbbbbb:#555555:#ff5555:#7df71d:#ffff55:#62cbe8:#ff9bf5:#00ccd8:#ffffff:#171717:#bbbbbb:#bbbbbb"});
            themes.add ({"nighty", "#373d48:#9b3e46:#095b32:#808020:#1d3e6f:#823065:#3a7458:#828282:#5c6370:#d0555f:#119955:#dfe048:#4674b8:#ed86c9:#70d2a4:#dfdfdf:#2f2f2f:#dfdfdf:#dfdfdf"});
            themes.add ({"Nord", "#353535:#e64569:#89d287:#dab752:#439ecf:#d961dc:#64aaaf:#b3b3b3:#535353:#e4859a:#a2cca1:#e1e387:#6fbbe2:#e586e7:#96dcda:#dedede:#353535:#439ecf:#439ecf"});
            themes.add ({"Nord Light", "#353535:#e64569:#89d287:#dab752:#439ecf:#d961dc:#64aaaf:#b3b3b3:#535353:#e4859a:#a2cca1:#e1e387:#6fbbe2:#e586e7:#96dcda:#dedede:#ebeaf2:#004f7c:#439ecf"});
            themes.add ({"Novel", "#000000:#cc0000:#009600:#d06b00:#0000cc:#cc00cc:#0087cc:#cccccc:#808080:#cc0000:#009600:#d06b00:#0000cc:#cc00cc:#0087cc:#ffffff:#dfdbc3:#3b2322:#3b2322"});
            themes.add ({"Obsidian", "#000000:#a60001:#00bb00:#fecd22:#3a9bdb:#bb00bb:#00bbbb:#bbbbbb:#555555:#ff0003:#93c863:#fef874:#a1d7ff:#ff55ff:#55ffff:#ffffff:#283033:#cdcdcd:#cdcdcd"});
            themes.add ({"Ccean", "#000000:#990000:#00a600:#999900:#0000b2:#b200b2:#00a6b2:#bfbfbf:#666666:#e50000:#00d900:#e5e500:#0000ff:#e500e5:#00e5e5:#e5e5e5:#224fbc:#ffffff:#ffffff"});
            themes.add ({"Ocean Dark", "#4f4f4f:#af4b57:#afd383:#e5c079:#7d90a4:#a4799d:#85a6a5:#eeedee:#7b7b7b:#af4b57:#ceffab:#fffecc:#b5dcfe:#fb9bfe:#dfdffd:#fefffe:#1c1f27:#979cac:#979cac"});
            themes.add ({"Oceanic Next", "#121c21:#e44754:#89bd82:#f7bd51:#5486c0:#b77eb8:#50a5a4:#ffffff:#52606b:#e44754:#89bd82:#f7bd51:#5486c0:#b77eb8:#50a5a4:#ffffff:#121b21:#b3b8c3:#b3b8c3"});
            themes.add ({"Ollie", "#000000:#ac2e31:#31ac61:#ac4300:#2d57ac:#b08528:#1fa6ac:#8a8eac:#5b3725:#ff3d48:#3bff99:#ff5e1e:#4488ff:#ffc21d:#1ffaff:#5b6ea7:#222125:#8a8dae:#8a8dae"});
            themes.add ({"One Dark", "#000000:#e06c75:#98c379:#d19a66:#61afef:#c678dd:#56b6c2:#abb2bf:#5c6370:#e06c75:#98c379:#d19a66:#61afef:#c678dd:#56b6c2:#fffefe:#1e2127:#5c6370:#5c6370"});
            themes.add ({"One Half Black", "#282c34:#e06c75:#98c379:#e5c07b:#61afef:#c678dd:#56b6c2:#dcdfe4:#282c34:#e06c75:#98c379:#e5c07b:#61afef:#c678dd:#56b6c2:#dcdfe4:#000000:#dcdfe4:#dcdfe4"});
            themes.add ({"One Light", "#000000:#da3e39:#41933e:#855504:#315eee:#930092:#0e6fad:#8e8f96:#2a2b32:#da3e39:#41933e:#855504:#315eee:#930092:#0e6fad:#fffefe:#f8f8f8:#2a2b32:#2a2b32"});
            themes.add ({"palenight", "#292d3e:#f07178:#c3e88d:#ffcb6b:#82aaff:#c792ea:#60adec:#abb2bf:#959dcb:#f07178:#c3e88d:#ff5572:#82aaff:#ffcb6b:#676e95:#fffefe:#292d3e:#bfc7d5:#bfc7d5"});
            themes.add ({"Pali", "#0a0a0a:#ab8f74:#74ab8f:#8fab74:#8f74ab:#ab748f:#748fab:#f2f2f2:#5d5d5d:#ff1d62:#9cc3af:#ffd00a:#af9cc3:#ff1d62:#4bb8fd:#a020f0:#232e37:#d9e6f2:#d9e6f2"});
            themes.add ({"PaperColor Dark", "#1c1c1c:#af005f:#5faf00:#d7af5f:#5fafd7:#808080:#d7875f:#d0d0d0:#585858:#5faf5f:#afd700:#af87d7:#ffaf00:#ff5faf:#00afaf:#5f8787:#1c1c1c:#d0d0d0:#d0d0d0"});
            themes.add ({"PaperColor Light", "#eeeeee:#af0000:#008700:#5f8700:#0087af:#878787:#005f87:#444444:#bcbcbc:#d70000:#d70087:#8700af:#d75f00:#d75f00:#005faf:#005f87:#eeeeee:#444444:#444444"});
            themes.add ({"Paraiso Dark", "#2f1e2e:#ef6155:#48b685:#fec418:#06b6ef:#815ba4:#5bc4bf:#a39e9b:#776e71:#ef6155:#48b685:#fec418:#06b6ef:#815ba4:#5bc4bf:#e7e9db:#2f1e2e:#a39e9b:#a39e9b"});
            themes.add ({"Paul Millr", "#2a2a2a:#ff0000:#79ff0f:#d3bf00:#396bd7:#b449be:#66ccff:#bbbbbb:#666666:#ff0080:#66ff66:#f3d64e:#709aed:#db67e6:#7adff2:#ffffff:#000000:#f2f2f2:#f2f2f2"});
            themes.add ({"Pencil Dark", "#212121:#c30771:#10a778:#a89c14:#008ec4:#523c79:#20a5ba:#d9d9d9:#424242:#fb007a:#5fd7af:#f3e430:#20bbfc:#6855de:#4fb8cc:#f1f1f1:#212121:#f1f1f1:#f1f1f1"});
            themes.add ({"Pencil Light", "#212121:#c30771:#10a778:#a89c14:#008ec4:#523c79:#20a5ba:#d9d9d9:#424242:#fb007a:#5fd7af:#f3e430:#20bbfc:#6855de:#4fb8cc:#f1f1f1:#f1f1f1:#424242:#424242"});
            themes.add ({"Peppermint", "#353535:#e64569:#89d287:#dab752:#439ecf:#d961dc:#64aaaf:#b3b3b3:#535353:#e4859a:#a2cca1:#e1e387:#6fbbe2:#e586e7:#96dcda:#dedede:#000000:#c7c7c7:#bbbbbb"});
            themes.add ({"Pnevma", "#2f2e2d:#a36666:#90a57d:#d7af87:#7fa5bd:#c79ec4:#8adbb4:#d0d0d0:#4a4845:#d78787:#afbea2:#e4c9af:#a1bdce:#d7beda:#b1e7dd:#efefef:#1c1c1c:#d0d0d0:#d0d0d0"});
            themes.add ({"PowerShell", "#000000:#7e0008:#098003:#c4a000:#010083:#d33682:#0e807f:#7f7c7f:#808080:#ef2929:#1cfe3c:#fefe45:#268ad2:#fe13fa:#29fffe:#c2c1c3:#052454:#f6f6f7:#f6f6f7"});
            themes.add ({"Pro", "#000000:#990000:#00a600:#999900:#2009db:#b200b2:#00a6b2:#bfbfbf:#666666:#e50000:#00d900:#e5e500:#0000ff:#e500e5:#00e5e5:#e5e5e5:#000000:#f2f2f2:#f2f2f2"});
            themes.add ({"Red Alert", "#000000:#d62e4e:#71be6b:#beb86b:#489bee:#e979d7:#6bbeb8:#d6d6d6:#262626:#e02553:#aff08c:#dfddb7:#65aaf1:#ddb7df:#b7dfdd:#ffffff:#762423:#ffffff:#ffffff"});
            themes.add ({"Red Sands", "#000000:#ff3f00:#00bb00:#e7b000:#0072ff:#bb00bb:#00bbbb:#bbbbbb:#555555:#bb0000:#00bb00:#e7b000:#0072ae:#ff55ff:#55ffff:#ffffff:#7a251e:#d7c9a7:#d7c9a7"});
            themes.add ({"Relaxed", "#151515:#bc5653:#909d63:#ebc17a:#6a8799:#b06698:#c9dfff:#d9d9d9:#636363:#bc5653:#a0ac77:#ebc17a:#7eaac7:#b06698:#acbbd0:#f7f7f7:#353a44:#d9d9d9:#d9d9d9"});
            themes.add ({"Rippedcasts", "#000000:#cdaf95:#a8ff60:#bfbb1f:#75a5b0:#ff73fd:#5a647e:#bfbfbf:#666666:#eecbad:#bcee68:#e5e500:#86bdc9:#e500e5:#8c9bc4:#e5e5e5:#2b2b2b:#ffffff:#ffffff"});
            themes.add ({"Royal", "#241f2b:#91284c:#23801c:#b49d27:#6580b0:#674d96:#8aaabe:#524966:#312d3d:#d5356c:#2cd946:#fde83b:#90baf9:#a479e3:#acd4eb:#9e8cbd:#100815:#514968:#514968"});
            themes.add ({"Sat", "#000000:#dd0007:#07dd00:#ddd600:#0007dd:#d600dd:#00ddd6:#f2f2f2:#7d7d7d:#ff7478:#78ff74:#fffa74:#7478ff:#fa74ff:#74fffa:#ffffff:#758480:#23476a:#23476a"});
            themes.add ({"Sea Shells", "#17384c:#d15123:#027c9b:#fca02f:#1e4950:#68d4f1:#50a3b5:#deb88d:#434b53:#d48678:#628d98:#fdd39f:#1bbcdd:#bbe3ee:#87acb4:#fee4ce:#09141b:#deb88d:#deb88d"});
            themes.add ({"Seafoam Pastel", "#757575:#825d4d:#728c62:#ada16d:#4d7b82:#8a7267:#729494:#e0e0e0:#8a8a8a:#cf937a:#98d9aa:#fae79d:#7ac3cf:#d6b2a1:#ade0e0:#e0e0e0:#243435:#d4e7d4:#d4e7d4"});
            themes.add ({"Seti", "#323232:#c22832:#8ec43d:#e0c64f:#43a5d5:#8b57b5:#8ec43d:#eeeeee:#323232:#c22832:#8ec43d:#e0c64f:#43a5d5:#8b57b5:#8ec43d:#ffffff:#111213:#cacecd:#cacecd"});
            themes.add ({"Shaman", "#012026:#b2302d:#00a941:#5e8baa:#449a86:#00599d:#5d7e19:#405555:#384451:#ff4242:#2aea5e:#8ed4fd:#61d5ba:#1298ff:#98d028:#58fbd6:#001015:#405555:#405555"});
            themes.add ({"Shel", "#2c2423:#ab2463:#6ca323:#ab6423:#2c64a2:#6c24a2:#2ca363:#918988:#918988:#f588b9:#c2ee86:#f5ba86:#8fbaec:#c288ec:#8feeb9:#f5eeec:#2a201f:#4882cd:#4882cd"});
            themes.add ({"Slate", "#222222:#e2a8bf:#81d778:#c4c9c0:#264b49:#a481d3:#15ab9c:#02c5e0:#ffffff:#ffcdd9:#beffa8:#d0ccca:#7ab0d2:#c5a7d9:#8cdfe0:#e0e0e0:#222222:#35b1d2:#35b1d2"});
            themes.add ({"Smyck", "#000000:#c75646:#8eb33b:#d0b03c:#72b3cc:#c8a0d1:#218693:#b0b0b0:#5d5d5d:#e09690:#cdee69:#ffe377:#9cd9f0:#fbb1f9:#77dfd8:#f7f7f7:#242424:#f7f7f7:#f7f7f7"});
            themes.add ({"Snazzy", "#282a36:#ff5c57:#5af78e:#f3f99d:#57c7ff:#ff6ac1:#9aedfe:#f1f1f0:#686868:#ff5c57:#5af78e:#f3f99d:#57c7ff:#ff6ac1:#9aedfe:#eff0eb:#282a36:#eff0eb:#97979b"});
            themes.add ({"Soft Server", "#000000:#a2686a:#9aa56a:#a3906a:#6b8fa3:#6a71a3:#6ba58f:#99a3a2:#666c6c:#dd5c60:#bfdf55:#deb360:#62b1df:#606edf:#64e39c:#d2e0de:#242626:#99a3a2:#99a3a2"});
            themes.add ({"Solarized Darcula", "#25292a:#f24840:#629655:#b68800:#2075c7:#797fd4:#15968d:#d2d8d9:#25292a:#f24840:#629655:#b68800:#2075c7:#797fd4:#15968d:#d2d8d9:#3d3f41:#d2d8d9:#d2d8d9"});
            themes.add ({"Solarized Dark", "#073642:#dc322f:#859900:#cf9a6b:#268bd2:#d33682:#2aa198:#eee8d5:#657b83:#d87979:#88cf76:#657b83:#2699ff:#d33682:#43b8c3:#fdf6e3:#002b36:#839496:#839496"});
            themes.add ({"Solarized Dark Higher Contrast", "#002831:#d11c24:#6cbe6c:#a57706:#2176c7:#c61c6f:#259286:#eae3cb:#006488:#f5163b:#51ef84:#b27e28:#178ec8:#e24d8e:#00b39e:#fcf4dc:#001e27:#9cc2c3:#9cc2c3"});
            themes.add ({"Solarized Light", "#073642:#dc322f:#859900:#b58900:#268bd2:#d33682:#2aa198:#eee8d5:#002b36:#cb4b16:#586e75:#657b83:#839496:#6c71c4:#93a1a1:#fdf6e3:#fdf6e3:#657b83:#657b83"});
            themes.add ({"Spacedust", "#6e5346:#e35b00:#5cab96:#e3cd7b:#0f548b:#e35b00:#06afc7:#f0f1ce:#684c31:#ff8a3a:#aecab8:#ffc878:#67a0ce:#ff8a3a:#83a7b4:#fefff1:#0a1e24:#ecf0c1:#ecf0c1"});
            themes.add ({"SpaceGray", "#000000:#b04b57:#87b379:#e5c179:#7d8fa4:#a47996:#85a7a5:#b3b8c3:#000000:#b04b57:#87b379:#e5c179:#7d8fa4:#a47996:#85a7a5:#ffffff:#20242d:#b3b8c3:#b3b8c3"});
            themes.add ({"SpaceGray Eighties", "#15171c:#ec5f67:#81a764:#fec254:#5486c0:#bf83c1:#57c2c1:#efece7:#555555:#ff6973:#93d493:#ffd256:#4d84d1:#ff55ff:#83e9e4:#ffffff:#222222:#bdbaae:#bdbaae"});
            themes.add ({"SpaceGray Eighties Dull", "#15171c:#b24a56:#92b477:#c6735a:#7c8fa5:#a5789e:#80cdcb:#b3b8c3:#555555:#ec5f67:#89e986:#fec254:#5486c0:#bf83c1:#58c2c1:#ffffff:#222222:#c9c6bc:#c9c6bc"});
            themes.add ({"Spring", "#000000:#ff4d83:#1f8c3b:#1fc95b:#1dd3ee:#8959a8:#3e999f:#ffffff:#000000:#ff0021:#1fc231:#d5b807:#15a9fd:#8959a8:#3e999f:#ffffff:#0a1e24:#ecf0c1:#ecf0c1"});
            themes.add ({"Square", "#050505:#e9897c:#b6377d:#ecebbe:#a9cdeb:#75507b:#c9caec:#f2f2f2:#141414:#f99286:#c3f786:#fcfbcc:#b6defb:#ad7fa8:#d7d9fc:#e2e2e2:#0a1e24:#a1a1a1:#a1a1a1"});
            themes.add ({"Srcery", "#1c1b19:#ff3128:#519f50:#fbb829:#5573a3:#e02c6d:#0aaeb3:#918175:#2d2b28:#f75341:#98bc37:#fed06e:#8eb2f7:#e35682:#53fde9:#fce8c3:#282828:#ebdbb2:#ebdbb2"});
            themes.add ({"summer-pop", "#666666:#ff1e8e:#8eff1e:#fffb00:#1e8eff:#e500e5:#00e5e5:#e5e5e5:#666666:#ff1e8e:#8eff1e:#fffb00:#1e8eff:#e500e5:#00e5e5:#e5e5e5:#272822:#ffffff:#ffffff"});
            themes.add ({"Sundried", "#302b2a:#a7463d:#587744:#9d602a:#485b98:#864651:#9c814f:#c9c9c9:#4d4e48:#aa000c:#128c21:#fc6a21:#7999f7:#fd8aa1:#fad484:#ffffff:#1a1818:#c9c9c9:#c9c9c9"});
            themes.add ({"Symphonic", "#000000:#dc322f:#56db3a:#ff8400:#0084d4:#b729d9:#ccccff:#ffffff:#1b1d21:#dc322f:#56db3a:#ff8400:#0084d4:#b729d9:#ccccff:#ffffff:#000000:#ffffff:#ffffff"});
            themes.add ({"SynthWave", "#011627:#fe4450:#72f1b8:#fede5d:#03edf9:#ff7edb:#03edf9:#ffffff:#575656:#fe4450:#72f1b8:#fede5d:#03edf9:#ff7edb:#03edf9:#ffffff:#262335:#ffffff:#03edf9"});
            themes.add ({"Teerb", "#1c1c1c:#d68686:#aed686:#d7af87:#86aed6:#d6aed6:#8adbb4:#d0d0d0:#1c1c1c:#d68686:#aed686:#e4c9af:#86aed6:#d6aed6:#b1e7dd:#efefef:#262626:#d0d0d0:#d0d0d0"});
            themes.add ({"Terminal Basic", "#000000:#990000:#00a600:#999900:#0000b2:#b200b2:#00a6b2:#bfbfbf:#666666:#e50000:#00d900:#e5e500:#0000ff:#e500e5:#00e5e5:#e5e5e5:#ffffff:#000000:#000000"});
            themes.add ({"Terminix Dark", "#282a2e:#a54242:#a1b56c:#de935f:#225555:#85678f:#5e8d87:#777777:#373b41:#c63535:#608360:#fa805a:#449da1:#ba8baf:#86c1b9:#c5c8c6:#091116:#868a8c:#868a8c"});
            themes.add ({"Thayer Bright", "#1b1d1e:#f92672:#4df840:#f4fd22:#2757d6:#8c54fe:#38c8b5:#ccccc6:#505354:#ff5995:#b6e354:#feed6c:#3f78ff:#9e6ffe:#23cfd5:#f8f8f2:#1b1d1e:#f8f8f8:#f8f8f8"});
            themes.add ({"Tin", "#000000:#8d534e:#4e8d53:#888d4e:#534e8d:#8d4e88:#4e888d:#ffffff:#000000:#b57d78:#78b57d:#b0b578:#7d78b5:#b578b0:#78b0b5:#ffffff:#2e2e35:#ffffff:#ffffff"});
            themes.add ({"Tomorrow", "#000000:#c82828:#718c00:#eab700:#4171ae:#8959a8:#3e999f:#fffefe:#000000:#c82828:#708b00:#e9b600:#4170ae:#8958a7:#3d999f:#fffefe:#ffffff:#4d4d4c:#4c4c4c"});
            themes.add ({"Tomorrow Night", "#000000:#cc6666:#b5bd68:#f0c674:#81a2be:#b293bb:#8abeb7:#fffefe:#000000:#cc6666:#b5bd68:#f0c574:#80a1bd:#b294ba:#8abdb6:#fffefe:#1d1f21:#c5c8c6:#c4c8c5"});
            themes.add ({"Tomorrow Night Blue", "#000000:#ff9da3:#d1f1a9:#ffeead:#bbdaff:#ebbbff:#99ffff:#fffefe:#000000:#ff9ca3:#d0f0a8:#ffedac:#badaff:#ebbaff:#99ffff:#fffefe:#002451:#fffefe:#fffefe"});
            themes.add ({"Tomorrow Night Bright", "#000000:#d54e53:#b9ca49:#e7c547:#79a6da:#c397d8:#70c0b1:#fffefe:#000000:#d44d53:#b9c949:#e6c446:#79a6da:#c396d7:#70c0b1:#fffefe:#000000:#e9e9e9:#e9e9e9"});
            themes.add ({"Tomorrow Night Eighties", "#000000:#f27779:#99cc99:#ffcc66:#6699cc:#cc99cc:#66cccc:#fffefe:#000000:#f17779:#99cc99:#ffcc66:#6699cc:#cc99cc:#66cccc:#fffefe:#2c2c2c:#cccccc:#cccccc"});
            themes.add ({"Toy Chest", "#2c3f58:#be2d26:#1a9172:#db8e27:#325d96:#8a5edc:#35a08f:#23d183:#336889:#dd5944:#31d07b:#e7d84b:#34a6da:#ae6bdc:#42c3ae:#d5d5d5:#24364b:#31d07b:#31d07b"});
            themes.add ({"Treehouse", "#321300:#b2270e:#44a900:#aa820c:#58859a:#97363d:#b25a1e:#786b53:#433626:#ed5d20:#55f238:#f2b732:#85cfed:#e14c5a:#f07d14:#ffc800:#191919:#786b53:#786b53"});
            themes.add ({"Twilight", "#141414:#c06d44:#afb97a:#c2a86c:#44474a:#b4be7c:#778385:#ffffd4:#262626:#de7c4c:#ccd88c:#e2c47e:#5a5e62:#d0dc8e:#8a989b:#ffffd4:#141414:#ffffd4:#ffffd4"});
            themes.add ({"Ura", "#000000:#c21b6f:#6fc21b:#c26f1b:#1b6fc2:#6f1bc2:#1bc26f:#808080:#808080:#ee84b9:#b9ee84:#eeb984:#84b9ee:#b984ee:#84eeb9:#e5e5e5:#feffee:#23476a:#23476a"});
            themes.add ({"Urple", "#000000:#b0425b:#37a415:#ad5c42:#564d9b:#6c3ca1:#808080:#87799c:#5d3225:#ff6388:#29e620:#f08161:#867aed:#a05eee:#eaeaea:#bfa3ff:#1b1b23:#877a9b:#877a9b"});
            themes.add ({"Vag", "#303030:#a87139:#39a871:#71a839:#7139a8:#a83971:#3971a8:#8a8a8a:#494949:#b0763b:#3bb076:#76b03b:#763bb0:#b03b76:#3b76b0:#cfcfcf:#191f1d:#d9e6f2:#d9e6f2"});
            themes.add ({"Vaughn", "#25234f:#705050:#60b48a:#dfaf8f:#5555ff:#f08cc3:#8cd0d3:#709080:#709080:#dca3a3:#60b48a:#f0dfaf:#5555ff:#ec93d3:#93e0e3:#ffffff:#25234f:#dcdccc:#dcdccc"});
            themes.add ({"Vibrant Ink", "#878787:#ff6600:#ccff04:#ffcc00:#44b4cc:#9933cc:#44b4cc:#f5f5f5:#555555:#ff0000:#00ff00:#ffff00:#0000ff:#ff00ff:#00ffff:#e5e5e5:#000000:#ffffff:#ffffff"});
            themes.add ({"VS Code Dark+", "#6a787a:#e9653b:#39e9a8:#e5b684:#44aae6:#e17599:#3dd5e7:#c3dde1:#598489:#e65029:#00ff9a:#e89440:#009afb:#ff578f:#5fffff:#d9fbff:#1e1e1e:#cccccc:#cccccc"});
            themes.add ({"Warm Neon", "#000000:#e24346:#39b13a:#dae145:#4261c5:#f920fb:#2abbd4:#d0b8a3:#fefcfc:#e97071:#9cc090:#ddda7a:#7b91d6:#f674ba:#5ed1e5:#d8c8bb:#404040:#afdab6:#afdab6"});
            themes.add ({"Wez", "#000000:#cc5555:#55cc55:#cdcd55:#5555cc:#cc55cc:#7acaca:#cccccc:#555555:#ff5555:#55ff55:#ffff55:#5555ff:#ff55ff:#55ffff:#ffffff:#000000:#b3b3b3:#b3b3b3"});
            themes.add ({"Wild Cherry", "#000507:#d94085:#2ab250:#ffd16f:#883cdc:#ececec:#c1b8b7:#fff8de:#009cc9:#da6bac:#f4dca5:#eac066:#308cba:#ae636b:#ff919d:#e4838d:#1f1726:#dafaff:#dafaff"});
            themes.add ({"Wombat", "#000000:#ff615a:#b1e969:#ebd99c:#5da9f6:#e86aff:#82fff7:#dedacf:#313131:#f58c80:#ddf88f:#eee5b2:#a5c7ff:#ddaaff:#b7fff9:#ffffff:#171717:#dedacf:#dedacf"});
            themes.add ({"Wryan", "#333333:#8c4665:#287373:#7c7c99:#395573:#5e468c:#31658c:#899ca1:#3d3d3d:#bf4d80:#53a6a6:#9e9ecb:#477ab3:#7e62b3:#6096bf:#c0c0c0:#101010:#999993:#999993"});
            themes.add ({"Wzoreck", "#2e3436:#fc6386:#424043:#fce94f:#fb976b:#75507b:#34e2e2:#ffffff:#989595:#fc6386:#a9dc76:#fce94f:#fb976b:#ab9df2:#34e2e2:#d1d1c0:#424043:#fcfcfa:#fcfcfa"});
            themes.add ({"Zenburn", "#4d4d4d:#705050:#60b48a:#f0dfaf:#506070:#dc8cc3:#8cd0d3:#dcdccc:#709080:#dca3a3:#c3bf9f:#e0cf9f:#94bff3:#ec93d3:#93e0e3:#ffffff:#3f3f3f:#dcdccc:#dcdccc"});
        }

        public static string get_active_palette () {
            var palette = Application.settings.get_string ("palette");
            var background = Application.settings.get_string ("background");
            var foreground = Application.settings.get_string ("foreground");
            var cursor = Application.settings.get_string ("cursor-color");

            return @"$palette:$background:$foreground:$cursor";
        }

        public static void set_active_palette (string input) {
            var input_palette = input.split (":");
            if (input_palette.length != Terminal.Themes.PALETTE_SIZE) {
                warning ("Length of palette setting does not match palette size");
                return;
            }

            var background = input_palette[Terminal.Themes.PALETTE_SIZE - 3];
            var foreground = input_palette[Terminal.Themes.PALETTE_SIZE - 2];
            var cursor = input_palette[Terminal.Themes.PALETTE_SIZE - 1];
            var palette_length = input.length - background.length - foreground.length - cursor.length - 3;
            var palette = input.substring (0, palette_length);

            Application.settings.set_string ("palette", palette);
            Application.settings.set_string ("background", background);
            Application.settings.set_string ("foreground", foreground);
            Application.settings.set_string ("cursor-color", cursor);
        }

        public static string get_active_name () {
            var palette = get_active_palette ();

            foreach (Terminal.Theme theme in themes) {
                if (theme.palette == palette) {
                    return theme.name;
                }
            }

            return "Custom";
        }

        public static void set_active_name (string name) {
            foreach (Terminal.Theme theme in themes) {
                if (theme.name == name) {
                    set_active_palette (theme.palette);
                }
            }
        }
    }

    public struct Theme {
        string name;
        string palette;
    }
}
