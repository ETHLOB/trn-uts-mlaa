# The Brief

A large Australian digital bank has hired your consulting team to help it unlock value from its data assets. Over the past several years, the bank has collected data from customer onboarding, banking transactions, cards, devices, digital banking sessions, loans, marketing campaigns, and product portfolios. The bank has recently invested in its data infrastructure and now wants to leverage machine learning and artificial intelligence to improve customer experiences, manage risk, grow revenue, and improve operational efficiency. The bank's executives are not experts in data science and machine learning. Your team has therefore been tasked with:

- [ ] Understanding the available datasets
- [ ] Identifying meaningful business problems
- [ ] Translating business problems into machine learning problems
- [ ] Building and evaluating machine learning solutions
- [ ] Communicating findings to business stakeholders

Your business- and technically driven data science project should focus on solving business challenges using the provided digital banking warehouse.

## The Goal

There are many modelling pipeline archetypes we can apply to our client's data. However, we must define and implement the machine learning use cases separately using the shared banking warehouse. Collectively, the pipelines must cover the following four categories, in the following order:

1. Regression
2. Classification
3. Anomaly detection
4. Clustering

## What Does It Mean for Us?

This means that our work (the developers and their agents) will be individual, but we cannot confine ourselves to a "notebook-only" approach. The idea is to provide scalable, standardisable, and shareable solutions, leveraging not only good data science and analysis practices but also good Python development and tooling practices.

In other words, our solution must also provide sufficient answers to the following stakeholder demands:

1. Defining a clear and relevant business use case for the final machine learning experiments.
2. Translating the business problem into a machine learning problem in a reasonable, understandable way.
3. Performing a comprehensive exploratory data analysis (EDA) that allows the stakeholder to understand the overall data and justifies decision-making for predictive and prescriptive analysis.
4. Performing dimensionality reduction or engineering features whenever relevant, and demonstrating visible benefits to the business question.
5. Building baseline and advanced machine learning models.
6. Evaluating and communicating results.
7. Discussing ethical and responsible AI implications in the business context.

We should make the solution so that other team members or future collaborators can continue iterating on it. The main solution components in this regard are:

- Data cleaning
- Feature engineering
- Data preparation
- SQL/Pandas joins
- Shared utilities
- Visualisation techniques

## Example Banking Use Cases

We are encouraged to propose our own business problems and their corresponding solutions based on the data. However, the stakeholder has kindly provided some examples of current business questions:

## Regression

Examples:

- Predict future account balances
- Predict loan outstanding balances
- Predict customer lifetime value
- Predict monthly spending amounts
- Predict expected product profitability

### Classification

Examples:

- Predict whether a customer will accept a marketing campaign
- Predict whether a loan applicant is high risk or low risk
- Predict whether a customer will purchase a new banking product
- Predict whether a customer belongs to a vulnerable customer segment
- Predict whether a repayment will be late

### Anomaly Detection

Examples:

- Detect suspicious digital banking sessions
- Detect abnormal banking transactions
- Detect unusual customer spending patterns
- Detect potential account takeover activity
- Detect unusual transfer behaviours that may indicate money mule activity

### Clustering

Examples:

- Segment customers by banking behaviour
- Segment customers by financial wellbeing
- Cluster merchants based on transaction characteristics
- Cluster products based on profitability and usage
- Identify distinct customer personas

## Student Table Allocation

To encourage broad exploration of the warehouse, the stakeholder requires us to use at least the following tables for exploratory data analysis, depending on the problem archetype:

| **Problem Archetype** |                                        **Assigned EDA Tables**                                        |
|:---------------------:|:-----------------------------------------------------------------------------------------------------:|
| Classification        | customers, accounts, cards, loans                                                                     |
| Regression            | transactions, account_balance_history, economics                                                      |
| Anomaly Detection     | devices, digital_sessions, counterparty_transfers, merchant_reference, postcode_reference             |
| Clustering            | products, customer_products, marketing_campaigns, campaign_responses, loan_repayments, product_uptake |

However, for predictive and prescriptive analysis, we can complement the EDA results with a "complementary EDA" using features from other tables. These decisions must aim to include the information required to experiment with the established hypothesis.

On the other hand, some code has already been implemented in the notebooks. You should not modify it and should use the defined variables. The model training notebook (the one with the problem archetype name) will contain the final Python code for the solution. After running all the required experiments using the approaches enabled by the developer (the enabling of which depends entirely on the stakeholder's authorisation, so the developer and the agent are not required to solve everything) and drawing a **relevant, key, strategic, or significant** conclusion from the archetype's pipeline, we need to wrap the solution pipeline in a single clean notebook.

We need to save all datasets in the subfolder containing the notebooks:

```bash
36106/
    |
    -- assignment/
            |
            --- AT3/
                    |
                    --- data/
```

We need to write a final report presenting the business use cases for each archetype, assessing the benefits and drawbacks of each model's predictions, the datasets used for training (the feature collections), the approaches we took during the experimentation phase, the best results achieved, analyses of correct and incorrect predictions, the business impacts and ethical considerations of the models, and the final recommendation. The report should not exceed 16,000 words (4,000 words per archetype).

## Reproducibility Requirements

- The stakeholder staff must be able to execute notebooks using the provided instructions.
- All required dependencies must be documented.
- Missing files, undocumented setup steps, broken repositories, overengineering, or overall non working solution may result in rejection.
