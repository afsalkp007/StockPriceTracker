enum StockDescriptions {
    struct Info {
        let name: String
        let description: String
    }

    static let catalog: [String: Info] = [
        "AAPL": Info(name: "Apple Inc.", description: "Designs and sells consumer electronics, software, and online services including iPhone, Mac, and App Store."),
        "GOOG": Info(name: "Alphabet Inc.", description: "Parent company of Google, operating the world's largest search engine and digital advertising platform."),
        "TSLA": Info(name: "Tesla Inc.", description: "Designs and manufactures electric vehicles, energy storage, and solar products."),
        "AMZN": Info(name: "Amazon.com Inc.", description: "Global leader in e-commerce, cloud computing through AWS, and digital streaming."),
        "MSFT": Info(name: "Microsoft Corp.", description: "Develops software, cloud services, and hardware including Windows, Azure, and Xbox."),
        "NVDA": Info(name: "NVIDIA Corp.", description: "Designs GPUs and system-on-chip units for gaming, data centers, and AI workloads."),
        "META": Info(name: "Meta Platforms Inc.", description: "Operates Facebook, Instagram, and WhatsApp, focusing on social media and the metaverse."),
        "NFLX": Info(name: "Netflix Inc.", description: "Streaming entertainment service with over 230 million subscribers worldwide."),
        "AMD":  Info(name: "Advanced Micro Devices", description: "Designs high-performance CPUs and GPUs for computing and graphics markets."),
        "INTC": Info(name: "Intel Corp.", description: "World's largest semiconductor chip manufacturer, producing CPUs for server and PC markets."),
        "ORCL": Info(name: "Oracle Corp.", description: "Provides enterprise software, cloud services, and database management systems."),
        "CRM":  Info(name: "Salesforce Inc.", description: "Leading CRM platform enabling businesses to manage customer relationships and sales pipelines."),
        "ADBE": Info(name: "Adobe Inc.", description: "Offers creative and document software including Photoshop, Illustrator, and Acrobat."),
        "PYPL": Info(name: "PayPal Holdings", description: "Digital payments platform enabling online money transfers and commerce transactions."),
        "UBER": Info(name: "Uber Technologies", description: "Operates ride-hailing, food delivery, and freight logistics platforms globally."),
        "LYFT": Info(name: "Lyft Inc.", description: "Provides ride-hailing and bike-sharing services primarily in the United States."),
        "SPOT": Info(name: "Spotify Technology", description: "Audio streaming service offering music, podcasts, and audiobooks to over 600 million users."),
        "SNAP": Info(name: "Snap Inc.", description: "Operates Snapchat, a multimedia messaging app popular for ephemeral content and AR filters."),
        "BIDU": Info(name: "Baidu Inc.", description: "China's largest search engine and AI technology company, operating autonomous driving services."),
        "SHOP": Info(name: "Shopify Inc.", description: "E-commerce platform enabling businesses of all sizes to build and run online stores."),
        "SQ":   Info(name: "Block Inc.", description: "Operates Square payments, Cash App, and Bitcoin trading services for individuals and merchants."),
        "COIN": Info(name: "Coinbase Global", description: "Leading US cryptocurrency exchange platform for trading, storing, and using digital assets."),
        "RBLX": Info(name: "Roblox Corp.", description: "Online platform and game creation system where users build and play immersive 3D experiences."),
        "PLTR": Info(name: "Palantir Technologies", description: "Data analytics platform used by governments and enterprises for operational intelligence."),
        "HOOD": Info(name: "Robinhood Markets", description: "Commission-free investing app offering stocks, ETFs, options, and cryptocurrency trading."),
    ]

    static let symbols: [String] = Array(catalog.keys).sorted()
}
