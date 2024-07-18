use core::clone::Clone;
use core::option::OptionTrait;
use alexandria_encoding::base64::{Base64Encoder, Base64Decoder, Base64UrlEncoder, Base64UrlDecoder};

fn logo() -> ByteArray {
    "<svg xmlns=\"http://www.w3.org/2000/svg\" fill='#3DEC00' viewBox=\"0 0 10 16\"><g><g><path d=\"M1 2V0h8v2h1v10H7v4H3v-4H0V2zm1 4v4h2v2h2v-2h2V6H6v4H4V6z\"/></g></g></svg>"
}

fn create_rect() -> ByteArray {
    "<rect x='0.5' y='0.5' width='599' height='899' rx='27.5' fill='black' stroke='#3DEC00'/>"
}

fn create_text(
    text: ByteArray, x: ByteArray, y: ByteArray, fontsize: ByteArray, baseline: ByteArray
) -> ByteArray {
    "<text x='"
        + x
        + "' y='"
        + y
        + "' font-family='Courier, monospace' font-size='"
        + fontsize
        + "' fill='#3DEC00' text-anchor='start' dominant-baseline='"
        + baseline
        + "'>"
        + text
        + "</text>"
}

fn combine_elements(ref elements: Span<ByteArray>) -> ByteArray {
    let mut count: u8 = 1;

    let mut combined: ByteArray = "";
    loop {
        match elements.pop_front() {
            Option::Some(element) => {
                combined += element.clone();

                count += 1;
            },
            Option::None(()) => { break; }
        }
    };

    combined
}

fn create_svg(internals: ByteArray) -> ByteArray {
    "<svg xmlns='http://www.w3.org/2000/svg' width='600' height='900'>" + internals + "</svg>"
}

fn create_full_svg() -> ByteArray {
    let rect = create_rect();

    let logo_element = "<g transform='translate(25,25) scale(4)'>" + logo() + "</g>";

    // Update text elements
    let name = create_text("John Doe", "117", "117.136", "32", "middle");
    let id = create_text("#1234", "123", "61.2273", "24", "middle");
    let level = create_text("LVL 42", "208.008", "61.2273", "24", "middle");
    let health = create_text("100/100 HP", "453.527", "58.2727", "20", "right");
    let gold = create_text("1000 GLD", "475.09", "93.2727", "20", "right");

    // Stats
    let str = create_text("8 STR", "511.672", "128.273", "20", "right");
    let dex = create_text("8 DEX", "510.891", "163.273", "20", "right");
    let int = create_text("7 INT", "517.766", "198.273", "20", "right");
    let vit = create_text("5 VIT", "518.566", "233.273", "20", "right");
    let wis = create_text("9 WIS", "512.863", "268.273", "20", "right");
    let cha = create_text("10 CHA", "497.707", "303.273", "20", "right");
    let luck = create_text("2 LUCK", "496.594", "338.273", "20", "right");

    // Equipment sections
    let equipped_header = create_text("Equipped", "30", "183.136", "32", "middle");
    let bag_header = create_text("Bag", "30", "600.136", "32", "middle");

    // Combine all elements
    let mut elements = array![
        rect,
        logo_element,
        name,
        id,
        level,
        health,
        gold,
        str,
        dex,
        int,
        vit,
        wis,
        cha,
        luck,
        equipped_header,
        bag_header,
        create_text("Katana lvl 10", "30", "233.227", "24", "middle"),
        create_text("Helm lvl 20", "30", "272.227", "24", "middle"),
        create_text("Gloves lvl 20", "30", "311.227", "24", "middle"),
        create_text("Ring lvl 20", "30", "350.227", "24", "middle"),
        create_text("Greaves lvl 20", "30", "389.227", "24", "middle"),
        create_text("Sash lvl 10", "30", "428.227", "24", "middle"),
        create_text("Boots lvl 10", "30", "467.227", "24", "middle"),
        create_text("Necklace lvl 10", "30", "506.227", "24", "middle"),
        create_text("Katana lvl 10", "30", "644.273", "20", "middle"),
        create_text("Helm lvl 20", "30", "678.273", "20", "middle"),
        create_text("Ring lvl 20", "30", "712.273", "20", "middle"),
        create_text("Greaves lvl 20", "30", "746.273", "20", "middle"),
        create_text("Sash lvl 10", "30", "780.273", "20", "middle"),
        create_text("Boots lvl 10", "30", "814.273", "20", "middle"),
        create_text("Necklace lvl 10", "30", "848.273", "20", "middle"),
        create_text("Katana lvl 10", "311", "644.273", "20", "middle"),
        create_text("Helm lvl 20", "311", "678.273", "20", "middle"),
        create_text("Ring lvl 20", "311", "712.273", "20", "middle"),
        create_text("Greaves lvl 20", "311", "746.273", "20", "middle"),
        create_text("Sash lvl 10", "311", "780.273", "20", "middle"),
        create_text("Boots lvl 10", "311", "814.273", "20", "middle"),
        create_text("Necklace lvl 10", "311", "848.273", "20", "middle"),
    ]
        .span();

    let internals = combine_elements(ref elements);

    let svg = create_svg(internals);

    println!("{}", svg);

    svg
}


#[cfg(test)]
mod tests {
    use core::array::ArrayTrait;
    use super::{create_svg, create_rect, create_text, combine_elements, logo};

    #[test]
    fn print() {
        let rect = create_rect();

        let logo_element = "<g transform=\"translate(25,25) scale(4)\">" + logo() + "</g>";

        // Update text elements
        let name = create_text("John Doe", "117", "117.136", "32", "middle");
        let id = create_text("#1234", "123", "61.2273", "24", "middle");
        let level = create_text("LVL 42", "208.008", "61.2273", "24", "middle");
        let health = create_text("100/100 HP", "453.527", "58.2727", "20", "right");
        let gold = create_text("1000 GLD", "475.09", "93.2727", "20", "right");

        // Stats
        let str = create_text("8 STR", "511.672", "128.273", "20", "right");
        let dex = create_text("8 DEX", "510.891", "163.273", "20", "right");
        let int = create_text("7 INT", "517.766", "198.273", "20", "right");
        let vit = create_text("5 VIT", "518.566", "233.273", "20", "right");
        let wis = create_text("9 WIS", "512.863", "268.273", "20", "right");
        let cha = create_text("10 CHA", "497.707", "303.273", "20", "right");
        let luck = create_text("2 LUCK", "496.594", "338.273", "20", "right");

        // Equipment sections
        let equipped_header = create_text("Equipped", "30", "183.136", "32", "middle");
        let bag_header = create_text("Bag", "30", "600.136", "32", "middle");

        // Combine all elements
        let mut elements = array![
            rect,
            logo_element,
            name,
            id,
            level,
            health,
            gold,
            str,
            dex,
            int,
            vit,
            wis,
            cha,
            luck,
            equipped_header,
            bag_header,
            create_text("Katana lvl 10", "30", "233.227", "24", "middle"),
            create_text("Helm lvl 20", "30", "272.227", "24", "middle"),
            create_text("Gloves lvl 20", "30", "311.227", "24", "middle"),
            create_text("Ring lvl 20", "30", "350.227", "24", "middle"),
            create_text("Greaves lvl 20", "30", "389.227", "24", "middle"),
            create_text("Sash lvl 10", "30", "428.227", "24", "middle"),
            create_text("Boots lvl 10", "30", "467.227", "24", "middle"),
            create_text("Necklace lvl 10", "30", "506.227", "24", "middle"),
            create_text("Katana lvl 10", "30", "644.273", "20", "middle"),
            create_text("Helm lvl 20", "30", "678.273", "20", "middle"),
            create_text("Ring lvl 20", "30", "712.273", "20", "middle"),
            create_text("Greaves lvl 20", "30", "746.273", "20", "middle"),
            create_text("Sash lvl 10", "30", "780.273", "20", "middle"),
            create_text("Boots lvl 10", "30", "814.273", "20", "middle"),
            create_text("Necklace lvl 10", "30", "848.273", "20", "middle"),
            create_text("Katana lvl 10", "311", "644.273", "20", "middle"),
            create_text("Helm lvl 20", "311", "678.273", "20", "middle"),
            create_text("Ring lvl 20", "311", "712.273", "20", "middle"),
            create_text("Greaves lvl 20", "311", "746.273", "20", "middle"),
            create_text("Sash lvl 10", "311", "780.273", "20", "middle"),
            create_text("Boots lvl 10", "311", "814.273", "20", "middle"),
            create_text("Necklace lvl 10", "311", "848.273", "20", "middle"),
        ]
            .span();

        let internals = combine_elements(ref elements);

        let svg = create_svg(internals);

        println!("{}", svg);
    }
}
