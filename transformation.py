import csv
import json

def convert_to_json(input_file, output_file):
    
    with open(input_file, 'r', encoding='utf-8') as f: 
        reader = csv.reader(f, delimiter=';')
        data = []

        for row_num, row in enumerate(reader, start=1):
            
            if len(row) == 54:
                fact = {
                    "fact_key": int(row[0]),          
                    "order_key": int(row[1]),         
                    "product_key": int(row[2]),       
                    "customer": {                     
                        "name": row[3],
                        "phone": row[4],
                        "city": row[5],
                        "nation": row[6],
                        "region": row[7],
                        "address": row[8],
                        "mktsegment": row[9]
                    },
                    "product": {                      
                        "partkey": int(row[10]),
                        "name": row[11],
                        "mfgr": row[12],
                        "category": row[13],
                        "brand": row[14],
                        "color": row[15],
                        "type": row[16],
                        "size": int(row[17]),
                        "container": row[18]
                    },
                    "supplier": {                    
                        "supplier_key": int(row[19]),
                        "name": row[20],
                        "phone": row[21],
                        "city": row[22],
                        "nation": row[23],
                        "region": row[24],
                        "address": row[25]
                    },
                    "dim_time": {                     
                        "full_date": row[26],
                        "day_of_week": row[27],
                        "month": row[28],
                        "year": int(row[29]),
                        "year_month": row[30],
                        "month_year": row[31],
                        "day_of_month": int(row[32]),
                        "day_of_week_number": int(row[33]),
                        "week_of_year": int(row[34]),
                        "quarter": int(row[35]),
                        "holiday_flag": int(row[36]),
                        "season": row[37],
                        "is_weekend": int(row[38]),
                        "is_workday": int(row[39]),
                        "is_holiday": int(row[40]),
                        "is_peak_season": int(row[41])
                    },
                    "orderdate": row[42],            
                    "priority": row[43],             
                    "ship_priority": int(row[44]),  
                    "quantity_ordered": int(row[45]),
                    "extended_price": int(row[46]),  
                    "order_totalprice": int(row[47]),
                    "discount": int(row[48]),        
                    "revenue": int(row[49]),         
                    "supp_cost": int(row[50]),      
                    "tax": int(row[51]),             
                    "shipmode": row[52]             
                }
                data.append(fact)
            else:
                print(f"Erreur de format dans la ligne {row_num} (nombre de colonnes : {len(row)})")

    if data:
        with open(output_file, 'w', encoding='utf-8') as json_file:
            json.dump(data, json_file, indent=4)
        print(f"Les données ont été converties en JSON et sauvegardées dans {output_file}")
    else:
        print("Aucune donnée valide trouvée.")

input_file = 'nlineorder.csv' 
output_file = 'fact_table_de.json'  

convert_to_json(input_file, output_file)
