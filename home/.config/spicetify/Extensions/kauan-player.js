(function kauanPlayer() {
    const sleep = ms =>
        new Promise(resolve => setTimeout(resolve, ms));


    async function waitForSpotify() {
        while (
            typeof Spicetify === "undefined" ||
            !Spicetify.Player
        ) {
            await sleep(250);
        }
    }


    async function waitForMain() {
        let main = null;

        while (!main) {
            main = document.querySelector(".Root__main-view");

            if (!main)
                await sleep(250);
        }

        return main;
    }


    function getNativeCover() {
        const selectors = [
            '[data-testid="cover-art-image"]',
            '[data-testid="cover-art-image"] img',
            '.cover-art-image img',
            '.Root__now-playing-bar img'
        ];

        for (const selector of selectors) {
            const element = document.querySelector(selector);

            if (!element)
                continue;

            if (element.src)
                return element.src;

            const img = element.querySelector?.("img");

            if (img?.src)
                return img.src;
        }

        return "";
    }


    async function createPlayer() {
        if (document.querySelector("#kauan-nowplaying"))
            return;

        const main = await waitForMain();

        const player = document.createElement("div");

        player.id = "kauan-nowplaying";

        player.innerHTML = `
            <div class="kauan-cover-wrapper">
                <img id="kauan-cover">
            </div>

            <div id="kauan-song"></div>
            <div id="kauan-artist"></div>
        `;

        main.appendChild(player);
    }


    async function updatePlayer() {
        await createPlayer();

        const data = Spicetify.Player.data;

        if (!data?.item)
            return;

        const item = data.item;
        const metadata = item.metadata || {};

        const title =
            item.name ||
            metadata.title ||
            "Spotify";

        const artist =
            metadata.artist_name ||
            item.artists
                ?.map(artist => artist.name)
                .join(", ") ||
            "";

        let cover =
            item.album?.images?.[0]?.url ||
            item.images?.[0]?.url ||
            metadata.image_url ||
            "";

        if (!cover)
            cover = getNativeCover();

        const coverElement =
            document.querySelector("#kauan-cover");

        const songElement =
            document.querySelector("#kauan-song");

        const artistElement =
            document.querySelector("#kauan-artist");

        if (cover && coverElement)
            coverElement.src = cover;

        if (songElement)
            songElement.textContent = title;

        if (artistElement)
            artistElement.textContent = artist;
    }


    async function selectPlaylistsOnce() {
        /*
         * Tenta por alguns segundos durante a inicialização.
         * Depois para completamente.
         */

        for (let attempt = 0; attempt < 15; attempt++) {
            const sidebar =
                document.querySelector(".Root__nav-bar");

            if (sidebar) {
                const buttons =
                    [...sidebar.querySelectorAll("button")];

                const playlists =
                    buttons.find(button =>
                        /playlists?/i.test(
                            button.textContent.trim()
                        )
                    );

                if (playlists) {
                    if (
                        playlists.getAttribute(
                            "aria-pressed"
                        ) !== "true"
                    ) {
                        playlists.click();
                    }

                    return;
                }
            }

            await sleep(400);
        }
    }


    async function ensurePlayerExists() {
        /*
         * Checagem leve só para casos em que o Spotify
         * reconstrói a área principal.
         */

        if (!document.querySelector("#kauan-nowplaying")) {
            await createPlayer();
            await updatePlayer();
        }
    }


    async function start() {
        await waitForSpotify();

        await createPlayer();
        await updatePlayer();

        selectPlaylistsOnce();

        Spicetify.Player.addEventListener(
            "songchange",
            () => {
                setTimeout(updatePlayer, 100);
            }
        );

        /*
         * Uma checagem a cada 3 segundos é muito mais leve
         * que observar cada alteração do DOM.
         */
        setInterval(
            ensurePlayerExists,
            3000
        );
    }


    start();
})();
