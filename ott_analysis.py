import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("ott_subscriptions_1000.csv", parse_dates=[
    "Subscription_Date", "Cancellation_Date", "Last_Login_Date", "Data_As_Of_Date"
])
df.columns = df.columns.str.strip()
df["Subscription_Plan"] = df["Subscription_Plan"].str.strip().str.title()
df["Status"] = df["Status"].str.strip().str.title()
df["Monthly_Fee_INR"] = pd.to_numeric(df["Monthly_Fee_INR"], errors="coerce")
df = df.drop_duplicates(subset=["Customer_ID"]).dropna(
    subset=["Customer_ID", "Subscription_Date", "Monthly_Fee_INR"]
)

as_of = pd.Timestamp("2025-12-31")
df["Status_Clean"] = df["Cancellation_Date"].apply(
    lambda x: "Cancelled" if pd.notna(x) and x <= as_of else "Active"
)
total = df["Customer_ID"].nunique()
active = df.loc[df.Status_Clean == "Active", "Customer_ID"].nunique()
churned = df.loc[df.Status_Clean == "Cancelled", "Customer_ID"].nunique()
mrr = df.loc[df.Status_Clean == "Active", "Monthly_Fee_INR"].sum()
print("Total:", total, "Active:", active, "Churned:", churned)
print(f"Churn rate: {churned/total:.1%}" if total else "Churn rate: 0%")
print(f"Active MRR: Rs. {mrr:,.0f}; ARPU: Rs. {mrr/active:,.2f}" if active else "No active subscribers")

df["Cohort_Month"] = df["Subscription_Date"].dt.to_period("M").dt.to_timestamp()
observation_month = pd.Timestamp("2025-12-01")
records = []
for cohort, group in df.groupby("Cohort_Month"):
    size = group.Customer_ID.nunique()
    max_age = (observation_month.year-cohort.year)*12 + observation_month.month-cohort.month
    for age in range(max_age+1):
        month_end = cohort + pd.DateOffset(months=age) + pd.offsets.MonthEnd(0)
        retained = group[
            group.Cancellation_Date.isna() | (group.Cancellation_Date > month_end)
        ].Customer_ID.nunique()
        records.append({"Cohort_Month": cohort, "Month_Number": age,
                        "Cohort_Size": size, "Retained_Customers": retained,
                        "Retention_Rate": retained/size if size else 0})

cohort_long = pd.DataFrame(records)
cohort_matrix = cohort_long.pivot(index="Cohort_Month", columns="Month_Number",
                                  values="Retention_Rate")
cohort_long.to_csv("cohort_retention_long.csv", index=False)
cohort_matrix.to_csv("cohort_retention_matrix.csv")
df.to_csv("ott_subscriptions_clean.csv", index=False)
print("\\nCohort retention (%):")
print((cohort_matrix*100).round(1).to_string())

plt.figure(figsize=(12,6))
plt.imshow(cohort_matrix*100, aspect="auto", vmin=0, vmax=100)
plt.colorbar(label="Retention (%)")
plt.xticks(range(len(cohort_matrix.columns)), cohort_matrix.columns)
plt.yticks(range(len(cohort_matrix.index)),
           [d.strftime("%b %Y") for d in cohort_matrix.index])
plt.xlabel("Months since subscription")
plt.ylabel("Cohort month")
plt.title("OTT Customer Cohort Retention")
plt.tight_layout()
plt.savefig("cohort_retention_heatmap.png", dpi=150)
plt.show()
