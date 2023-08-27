// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract RealEstate {
    //--STATE VARIABLES
    struct Property {
        uint256 propertyId;
        address owner;
        uint256 price;
        string propertyTitle;
        string category;
        string images;
        string propertyAddress;
        string description;
        address[] reviewer;
        string[] reviews;
    }

    //--MAPPINGS
    mapping(uint256 => Property) private properties;
    uint256 public propertyIndex;

    //--EVENTS
    event PropertyListed(
        uint256 indexed id,
        address indexed owner,
        uint256 price
    );
    event PropertySold(
        uint256 indexed id,
        address indexed oldOwner,
        address indexed newOwner,
        uint256 price
    );
    event PropertyResold(
        uint256 indexed id,
        address indexed oldOwner,
        address indexed newOwner,
        uint256 price
    );

    //--REVIEW
    struct Review {
        address reviewer;
        uint256 propertyId;
        uint256 rating;
        string comment;
        uint256 likes;
    }

    struct Product {
        uint256 propertyId;
        uint256 totalRating;
        uint256 numOfReviews;
    }

    mapping(uint256 => Review[]) private reviews;
    mapping(address => uint256[]) private userReviews;
    mapping(uint256 => Product) private products;

    uint256 public reviewsCounter;

    event ReviewAdded(
        uint256 indexed propertyId,
        address indexed reviewer,
        uint256 rating,
        string comment
    );
    event ReviewLiked(
        uint256 indexed propertyId,
        uint256 indexed reviewIndex,
        address indexed liker,
        uint256 likes
    );

    // FUNTIONS IN CONTRACT

    function listProperty(
        address owner,
        uint256 price,
        string memory _propertyTitle,
        string memory _category,
        string memory _images,
        string memory _propertyAddress,
        string memory _description
    ) external returns (uint256) {
        require(price > 0, "price must be greater than 0");

        uint256 productId = propertyIndex++;
        Property storage property = properties[productId];

        property.propertyId = productId;
        property.owner = owner;
        property.price = price;
        property.propertyTitle = _propertyTitle;
        property.category = _category;
        property.images = _images;
        property.propertyAddress = _propertyAddress;
        property.description = _description;

        emit PropertyListed(productId, owner, price);
        return productId;
    }

    function updateProperty(
        address owner,
        uint256 productId,
        string memory _propertyTitle,
        string memory _category,
        string memory _image,
        string memory _propertyAddress,
        string memory _description
    ) external returns (uint256) {
        Property storage property = properties[productId];

        require(property.owner == owner, "Only property owner can update it");

        property.propertyTitle = _propertyTitle;
        property.category = _category;
        property.images = _image;
        property.propertyAddress = _propertyAddress;
        property.description = _description;

        return productId;
    }

    function updatePrice(
        address owner,
        uint256 productId,
        uint256 _price
    ) external returns (string memory) {
        Property storage property = properties[productId];

        require(
            property.owner == owner,
            "Only property owner can update price"
        );
        property.price = _price;

        return "Your property Price is updated";
    }

    function buyProperty(uint256 id, address buyer) external payable {
        uint256 amount = msg.value;

        require(amount >= properties[id].price, "Insufficent balance");

        Property storage property = properties[id];

        (bool sent, ) = payable(property.owner).call{value: amount}("");

        if (sent) {
            emit PropertySold(id, property.owner, buyer, amount);
            property.owner = buyer;
        }
    }

    function getAllProperties() public view returns (Property[] memory) {
        uint256 itemCount = propertyIndex;
        uint256 currentIndex = 0;

        Property[] memory items = new Property[](itemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            uint256 currentId = i + 1;

            Property storage currentItem = properties[currentId];
            items[currentIndex] = currentItem;
            currentIndex += 1;
        }
        return items;
    }

    function getProperty(
        uint256 id
    )
        external
        view
        returns (
            uint256,
            address,
            uint256,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory
        )
    {
        Property memory property = properties[id];
        return (
            property.propertyId,
            property.owner,
            property.price,
            property.propertyTitle,
            property.category,
            property.images,
            property.propertyAddress,
            property.description
        );
    }

    function getUserProperties(
        address user
    ) external view returns (Property[] memory) {
        uint256 totalItemCount = propertyIndex;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (properties[i + 1].owner == user) {
                itemCount += 1;
            }
        }

        Property[] memory item = new Property[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (properties[i + 1].owner == user) {
                uint256 currentId = i + 1;
                Property storage currentItem = properties[currentId];
                item[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return item;
    }

    // REVIEW FUNCTIONS

    function addReview(
        uint256 productId,
        uint256 rating,
        string calldata comment,
        address user
    ) external {
        require(rating >= 1 && rating <=5,'rating must be between 1 and 5');

        Property storage property = properties[productId];

        property.reviewer.push(user);
        property.reviews.push(comment);

        //--REVIEW SECTION
        reviews[productId].push(Review(user, productId, rating, comment, 0));
        userReviews[user].push(productId);
        products[productId].totalRating += rating;
        products[productId].numOfReviews++;

        emit ReviewAdded(productId, user, rating, comment);
        reviewsCounter++;

    }

    function getPropertyReviews(uint256 productId) external view returns (Review[] memory)
    {
        return reviews[productId];
    }

    function getUserReview(address user) external view returns (Review[] memory) 
    {
        uint256 totalReviews = userReviews[user].length;

        Review[] memory userPropertyReviews = new Review[](totalReviews);

        for(uint256 i = 0; i<userReviews[user].length; i++){
            uint256 productId = userReviews[user][i];
            Review[] memory propertyReviews = reviews[productId];


            for(uint256 j= 0; j< propertyReviews.length; j++)
            {
                if(propertyReviews[j].reviewer == user)
                {
                    userPropertyReviews[i] = propertyReviews[j];
                }
            }
        }

        return userPropertyReviews;
    }

    function likeReview(
        uint256 productId,
        uint256 reviewIndex,
        address user
    ) external {

        Review storage review = reviews[productId][reviewIndex];

        review.likes++; 
        emit ReviewLiked(productId, reviewIndex, user, review.likes);
    }

    function getHighestRatedProperty() external view returns (uint256) 
    {
        uint256 highestRating = 0;
        uint256 highestRatedProductId = 0;

        for(uint256 i = 0; i < reviewsCounter; i++)
        {
            uint256 productId = i+1;

            if(products[productId].numOfReviews > 0){
                uint256 avgRating = products[productId].totalRating / products[productId].numOfReviews;

                if(avgRating > highestRating){
                    highestRating = avgRating;
                    highestRatedProductId = productId;
                }
            }
        }  

        return highestRatedProductId;
    }
}


 