#!/bin/bash
# Infrastructure Topology Visualization Script

set -e

# Configuration
OUTPUT_DIR="./topology"
TERRAFORM_DIR="./terraform"
GRAPH_FILE="infrastructure.dot"
SVG_FILE="infrastructure.svg"
HTML_FILE="infrastructure.html"
JSON_FILE="infrastructure.json"

# Colors for different resource types
VPC_COLOR="#C4E0F9"
SUBNET_COLOR="#B4D4F2"
SG_COLOR="#A3C9EB"
EC2_COLOR="#92BEE4"
RDS_COLOR="#81B3DD"
ECS_COLOR="#70A8D6"
ALB_COLOR="#5F9DCF"
S3_COLOR="#4E92C8"
LAMBDA_COLOR="#3D87C1"
CLOUDWATCH_COLOR="#2C7CBA"
CLOUDFRONT_COLOR="#1B71B3"
ROUTE53_COLOR="#0A66AC"
IAM_COLOR="#005BA5"

echo "SmartSphere Infrastructure Topology Generator"
echo "=============================================="
echo

# Create output directory if it doesn't exist
mkdir -p ${OUTPUT_DIR}

# Check if required tools are installed
if ! command -v terraform &> /dev/null; then
    echo "Error: terraform is not installed"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed"
    exit 1
fi

if ! command -v dot &> /dev/null; then
    echo "Warning: Graphviz (dot) is not installed. SVG generation will be skipped."
    SKIP_SVG=true
fi

echo "Generating infrastructure topology..."

# Navigate to Terraform directory
cd ${TERRAFORM_DIR}

# Generate Terraform graph output
terraform graph -type=plan > ../${OUTPUT_DIR}/${GRAPH_FILE}

# Create a more readable version for visualization
cat > ../${OUTPUT_DIR}/${HTML_FILE} << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SmartSphere Infrastructure Topology</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            border-bottom: 1px solid #ddd;
            padding-bottom: 10px;
        }
        #visualization {
            width: 100%;
            height: 800px;
            border: 1px solid #ddd;
            margin-top: 20px;
        }
        .controls {
            margin: 20px 0;
            padding: 10px;
            background-color: #f9f9f9;
            border-radius: 5px;
        }
        button {
            background-color: #0066cc;
            color: white;
            border: none;
            padding: 8px 15px;
            margin-right: 10px;
            border-radius: 3px;
            cursor: pointer;
        }
        button:hover {
            background-color: #0055aa;
        }
        .legend {
            display: flex;
            flex-wrap: wrap;
            margin-top: 20px;
        }
        .legend-item {
            display: flex;
            align-items: center;
            margin-right: 20px;
            margin-bottom: 10px;
        }
        .legend-color {
            width: 20px;
            height: 20px;
            margin-right: 5px;
            border: 1px solid #ccc;
        }
        .details-panel {
            margin-top: 20px;
            padding: 10px;
            background-color: #f9f9f9;
            border-radius: 5px;
            max-height: 200px;
            overflow-y: auto;
        }
    </style>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/vis-network/9.1.2/vis-network.min.js"></script>
</head>
<body>
    <div class="container">
        <h1>SmartSphere Infrastructure Topology</h1>
        
        <div class="controls">
            <button id="zoom-in">Zoom In</button>
            <button id="zoom-out">Zoom Out</button>
            <button id="fit">Fit View</button>
            <button id="toggle-physics">Toggle Physics</button>
            <select id="layout-select">
                <option value="hierarchical">Hierarchical</option>
                <option value="force">Force-Directed</option>
                <option value="circular">Circular</option>
            </select>
            <label>
                <input type="checkbox" id="group-by-type" checked> Group by Type
            </label>
        </div>
        
        <div class="legend">
            <div class="legend-item">
                <div class="legend-color" style="background-color: ${VPC_COLOR};"></div>
                <span>VPC</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background-color: ${SUBNET_COLOR};"></div>
                <span>Subnet</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background-color: ${SG_COLOR};"></div>
                <span>Security Group</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background-color: ${EC2_COLOR};"></div>
                <span>EC2</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background-color: ${RDS_COLOR};"></div>
                <span>RDS</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background-color: ${ECS_COLOR};"></div>
                <span>ECS</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background-color: ${ALB_COLOR};"></div>
                <span>ALB</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background-color: ${S3_COLOR};"></div>
                <span>S3</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background-color: ${LAMBDA_COLOR};"></div>
                <span>Lambda</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background-color: ${CLOUDWATCH_COLOR};"></div>
                <span>CloudWatch</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background-color: ${CLOUDFRONT_COLOR};"></div>
                <span>CloudFront</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background-color: ${ROUTE53_COLOR};"></div>
                <span>Route53</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background-color: ${IAM_COLOR};"></div>
                <span>IAM</span>
            </div>
        </div>
        
        <div id="visualization"></div>
        
        <div class="details-panel" id="details-panel">
            <h3>Resource Details</h3>
            <p>Click on a resource to see details</p>
        </div>
    </div>

    <script>
        // Load and parse infrastructure data
        fetch('infrastructure.json')
            .then(response => response.json())
            .then(data => {
                // Create nodes and edges
                const nodes = new vis.DataSet(data.nodes);
                const edges = new vis.DataSet(data.edges);

                // Create the network
                const container = document.getElementById('visualization');
                const networkData = {
                    nodes: nodes,
                    edges: edges
                };
                
                // Configuration options
                const options = {
                    nodes: {
                        shape: 'box',
                        margin: 10,
                        font: {
                            size: 14
                        }
                    },
                    edges: {
                        arrows: {
                            to: { enabled: true, scaleFactor: 0.5 }
                        },
                        smooth: { type: 'continuous' }
                    },
                    physics: {
                        enabled: true,
                        hierarchicalRepulsion: {
                            centralGravity: 0.0,
                            springLength: 100,
                            springConstant: 0.01,
                            nodeDistance: 120
                        },
                        solver: 'hierarchicalRepulsion'
                    },
                    layout: {
                        hierarchical: {
                            direction: 'UD',
                            sortMethod: 'directed',
                            levelSeparation: 150
                        }
                    },
                    groups: {
                        vpc: { color: { background: '${VPC_COLOR}' } },
                        subnet: { color: { background: '${SUBNET_COLOR}' } },
                        sg: { color: { background: '${SG_COLOR}' } },
                        ec2: { color: { background: '${EC2_COLOR}' } },
                        rds: { color: { background: '${RDS_COLOR}' } },
                        ecs: { color: { background: '${ECS_COLOR}' } },
                        alb: { color: { background: '${ALB_COLOR}' } },
                        s3: { color: { background: '${S3_COLOR}' } },
                        lambda: { color: { background: '${LAMBDA_COLOR}' } },
                        cloudwatch: { color: { background: '${CLOUDWATCH_COLOR}' } },
                        cloudfront: { color: { background: '${CLOUDFRONT_COLOR}' } },
                        route53: { color: { background: '${ROUTE53_COLOR}' } },
                        iam: { color: { background: '${IAM_COLOR}' } }
                    }
                };
                
                // Initialize network
                const network = new vis.Network(container, networkData, options);
                
                // Add event listeners
                network.on('click', function(params) {
                    if (params.nodes.length > 0) {
                        const nodeId = params.nodes[0];
                        const node = nodes.get(nodeId);
                        document.getElementById('details-panel').innerHTML = 
                            '<h3>' + node.label + '</h3>' +
                            '<pre>' + JSON.stringify(node.details || {}, null, 2) + '</pre>';
                    }
                });
                
                // Controls
                document.getElementById('zoom-in').addEventListener('click', function() {
                    network.zoomIn(0.2);
                });
                
                document.getElementById('zoom-out').addEventListener('click', function() {
                    network.zoomOut(0.2);
                });
                
                document.getElementById('fit').addEventListener('click', function() {
                    network.fit();
                });
                
                document.getElementById('toggle-physics').addEventListener('click', function() {
                    options.physics.enabled = !options.physics.enabled;
                    network.setOptions({ physics: { enabled: options.physics.enabled } });
                });
                
                document.getElementById('layout-select').addEventListener('change', function(e) {
                    switch(e.target.value) {
                        case 'hierarchical':
                            network.setOptions({ 
                                layout: { hierarchical: { enabled: true } },
                                physics: { hierarchicalRepulsion: { enabled: true } }
                            });
                            break;
                        case 'force':
                            network.setOptions({ 
                                layout: { hierarchical: { enabled: false } },
                                physics: { barnesHut: { enabled: true } }
                            });
                            break;
                        case 'circular':
                            network.setOptions({
                                layout: { hierarchical: { enabled: false } },
                                physics: {
                                    forceAtlas2Based: {
                                        gravitationalConstant: -50,
                                        centralGravity: 0.01,
                                        springLength: 100,
                                        springConstant: 0.08
                                    },
                                    maxVelocity: 50,
                                    solver: 'forceAtlas2Based',
                                    timestep: 0.35,
                                    stabilization: { iterations: 150 }
                                }
                            });
                            break;
                    }
                });
                
                document.getElementById('group-by-type').addEventListener('change', function(e) {
                    const nodes = new vis.DataSet(data.nodes.map(node => {
                        if (e.target.checked) {
                            return { ...node, group: node.type };
                        } else {
                            return { ...node, group: undefined };
                        }
                    }));
                    
                    network.setData({ nodes, edges });
                });
            })
            .catch(error => {
                console.error('Error loading infrastructure data:', error);
                document.getElementById('visualization').innerHTML = 
                    '<div style="padding: 20px; color: red;">Error loading infrastructure data</div>';
            });
    </script>
</body>
</html>
EOL

echo "Generating JSON representation of the infrastructure..."

# Parse Terraform state to get resource details
terraform state pull > ../tmp_state.json 2>/dev/null || echo "Warning: Could not pull terraform state"

# Extract resources info and create JSON representation
terraform show -json > ../tmp_show.json 2>/dev/null || echo "Warning: Could not generate JSON"

# Create nodes and edges from the graph
NODES=()
EDGES=()

# Process the dot file to extract nodes and edges
nodes_pattern='[[:space:]]*"[^"]*" \[label=[^]]*\];'
edges_pattern='[[:space:]]*"[^"]*" -> "[^"]*"[^;]*;'

# Extract nodes
nodes=$(grep -E "${nodes_pattern}" ../${OUTPUT_DIR}/${GRAPH_FILE})
while IFS= read -r line; do
    # Extract node id and label
    node_id=$(echo "$line" | sed -E 's/[[:space:]]*"([^"]*)" \[label=.*/\1/')
    label=$(echo "$line" | sed -E 's/.*\[label="([^"]*)".*/\1/')
    
    # Determine node type
    type="other"
    color="#cccccc"
    
    if [[ "$label" == *"aws_vpc"* ]]; then
        type="vpc"
        color="${VPC_COLOR}"
    elif [[ "$label" == *"aws_subnet"* ]]; then
        type="subnet"
        color="${SUBNET_COLOR}"
    elif [[ "$label" == *"aws_security_group"* ]]; then
        type="sg"
        color="${SG_COLOR}"
    elif [[ "$label" == *"aws_instance"* ]]; then
        type="ec2"
        color="${EC2_COLOR}"
    elif [[ "$label" == *"aws_db_instance"* ]]; then
        type="rds"
        color="${RDS_COLOR}"
    elif [[ "$label" == *"aws_ecs"* ]]; then
        type="ecs"
        color="${ECS_COLOR}"
    elif [[ "$label" == *"aws_lb"* || "$label" == *"aws_alb"* ]]; then
        type="alb"
        color="${ALB_COLOR}"
    elif [[ "$label" == *"aws_s3"* ]]; then
        type="s3"
        color="${S3_COLOR}"
    elif [[ "$label" == *"aws_lambda"* ]]; then
        type="lambda"
        color="${LAMBDA_COLOR}"
    elif [[ "$label" == *"aws_cloudwatch"* ]]; then
        type="cloudwatch"
        color="${CLOUDWATCH_COLOR}"
    elif [[ "$label" == *"aws_cloudfront"* ]]; then
        type="cloudfront"
        color="${CLOUDFRONT_COLOR}"
    elif [[ "$label" == *"aws_route53"* ]]; then
        type="route53"
        color="${ROUTE53_COLOR}"
    elif [[ "$label" == *"aws_iam"* ]]; then
        type="iam"
        color="${IAM_COLOR}"
    fi
    
    # Create node JSON
    node="{\"id\": \"${node_id}\", \"label\": \"${label}\", \"type\": \"${type}\", \"group\": \"${type}\", \"color\": {\"background\": \"${color}\"}}"
    NODES+=("$node")
    
done <<< "$nodes"

# Extract edges
edges=$(grep -E "${edges_pattern}" ../${OUTPUT_DIR}/${GRAPH_FILE})
while IFS= read -r line; do
    # Extract source and target
    source=$(echo "$line" | sed -E 's/[[:space:]]*"([^"]*)" -> "[^"]*".*/\1/')
    target=$(echo "$line" | sed -E 's/[[:space:]]*"[^"]*" -> "([^"]*)".*/\1/')
    
    # Create edge JSON
    edge="{\"from\": \"${source}\", \"to\": \"${target}\"}"
    EDGES+=("$edge")
    
done <<< "$edges"

# Create the final JSON
JSON_CONTENT="{\"nodes\": [$(IFS=,; echo "${NODES[*]}")], \"edges\": [$(IFS=,; echo "${EDGES[*]}")], \"metadata\": {\"generatedAt\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\", \"project\": \"SmartSphere\"}}"

echo "${JSON_CONTENT}" > ../${OUTPUT_DIR}/${JSON_FILE}

# Generate SVG if Graphviz is installed
if [ -z "${SKIP_SVG}" ]; then
    echo "Generating SVG visualization..."
    dot -Tsvg ../${OUTPUT_DIR}/${GRAPH_FILE} -o ../${OUTPUT_DIR}/${SVG_FILE}
    echo "SVG visualization generated at ${OUTPUT_DIR}/${SVG_FILE}"
fi

echo "Done! Infrastructure topology visualization generated at:"
echo "- DOT file: ${OUTPUT_DIR}/${GRAPH_FILE}"
echo "- JSON representation: ${OUTPUT_DIR}/${JSON_FILE}"
echo "- Interactive HTML: ${OUTPUT_DIR}/${HTML_FILE}"

# Return to original directory
cd ..

echo
echo "To view the interactive visualization, open: ${OUTPUT_DIR}/${HTML_FILE}"
echo