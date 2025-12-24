namespace :db do
  desc "创建完整的律师模拟数据"
  task seed_lawyer_data: :environment do
    puts "开始创建律师模拟数据..."

    # 获取当前用户和组织
    user = User.first
    organization = Organization.first

    unless user && organization
      puts "错误: 请先创建用户和组织"
      exit
    end

    # 查找或更新现有 Profile
    profile = user.profile || Profile.new(user: user, organization: organization)

    # 基本信息
    profile.full_name = "张建国"
    profile.title = "高级合伙人律师"
    profile.company = "北京正大律师事务所"
    profile.department = "商事诉讼部"
    profile.phone = "138-0000-8888"
    profile.email = "zhangjianguo@lawfirm.com"
    profile.location = "北京市朝阳区建国路88号现代城A座15层"
    
    # 个人简介
    profile.bio = '张建国律师，从事法律工作18年，专注于公司法、合同法及商事诉讼领域。曾成功代理多起重大商事纠纷案件，涉案金额累计超过10亿元人民币。秉承"专业、高效、负责"的执业理念，为客户提供全方位的法律服务。'
    
    # 专业领域
    profile.specializations = "公司法务、合同纠纷、股权争议、并购重组、知识产权保护、劳动争议"
    
    # 统计数据
    profile.stats = {
      "cases" => "200+",
      "cases_label" => "成功案例",
      "experience" => "18年",
      "experience_label" => "执业经验",
      "clients" => "500+",
      "clients_label" => "服务客户",
      "rate" => "95%",
      "rate_label" => "胜诉率"
    }

    # 服务优势
    profile.service_advantage_1_title = "丰富的执业经验"
    profile.service_advantage_1_description = "18年法律从业经验，成功处理各类商事案件200余起，深谙法律实务操作，能够准确把握案件关键点"

    profile.service_advantage_2_title = "专业的团队支持"
    profile.service_advantage_2_description = "拥有一支由资深律师、法律顾问组成的专业团队，提供全方位、多层次的法律服务保障"

    profile.service_advantage_3_title = "高效的服务响应"
    profile.service_advantage_3_description = "建立24小时响应机制，第一时间解答客户疑问，及时处理紧急法律事务，确保客户利益最大化"

    # 服务流程
    profile.service_process_1_title = "案情咨询"
    profile.service_process_1_description = "免费提供30分钟初步咨询，了解案件基本情况，分析法律关系，评估案件可行性"

    profile.service_process_2_title = "方案制定"
    profile.service_process_2_description = "深入研究案情，制定详细的诉讼策略或解决方案，明确服务范围、时间节点和费用标准"

    profile.service_process_3_title = "专业代理"
    profile.service_process_3_description = "全程跟进案件进展，起草法律文书，参与谈判调解，出庭代理诉讼，维护客户合法权益"

    profile.service_process_4_title = "售后服务"
    profile.service_process_4_description = "案件结束后提供判决执行指导，长期法律风险防控建议，建立长期合作关系"

    # CTA 文案
    profile.cta_title = "需要法律帮助？立即联系我"
    profile.cta_description = "专业的法律服务，让您的权益得到最大保障"

    # 成员类别
    profile.member_category = "年度会员"

    # 设置状态
    profile.status = "approved"
    profile.onboarding_completed = true
    profile.slug = "zhangjianguo" if profile.slug.blank?

    profile.save!
    puts "✓ Profile 创建/更新成功: #{profile.full_name}"

    # 创建案例研究
    CaseStudy.where(profile: profile).destroy_all
    
    cases = [
      {
        title: "某科技公司股权转让纠纷案",
        category: "股权争议",
        date: "2023年6月",
        description: "成功代理某科技公司股东间股权转让纠纷，涉案金额3500万元。通过详实的证据链和精准的法律分析，为委托人争取到全额股权转让款及违约金，获得客户高度认可。",
        position: 1
      },
      {
        title: "大型企业并购法律服务",
        category: "并购重组",
        date: "2023年3月",
        description: "担任某上市公司收购境外企业的法律顾问，交易金额达2.8亿美元。全程参与尽职调查、合同谈判、审批申报等环节，确保交易顺利完成，帮助企业成功拓展国际市场。",
        position: 2
      },
      {
        title: "知名品牌商标侵权维权",
        category: "知识产权",
        date: "2022年11月",
        description: "代理某知名服装品牌商标侵权诉讼，成功打击多家侵权企业，为客户挽回经济损失超过1200万元，有效维护了品牌形象和市场地位。",
        position: 3
      },
      {
        title: "建筑工程合同纠纷仲裁",
        category: "合同纠纷",
        date: "2022年8月",
        description: "代理某建筑公司与开发商的工程款纠纷仲裁案，涉案金额8000万元。通过充分的证据准备和有力的仲裁陈述，最终为客户追回全部工程款及利息。",
        position: 4
      },
      {
        title: "高管劳动争议调解成功",
        category: "劳动争议",
        date: "2022年5月",
        description: "代理某外资企业高管与公司的劳动合同纠纷，涉及竞业限制、股权激励等复杂问题。通过专业调解，促成双方达成和解协议，既保护了客户权益，又维护了商业关系。",
        position: 5
      },
      {
        title: "跨境投资法律风险防控",
        category: "投资并购",
        date: "2022年2月",
        description: "为某民营企业集团提供跨境投资全程法律服务，涉及东南亚三国五个项目。通过系统的法律尽职调查和风险防控措施，帮助企业规避重大法律风险，投资项目全部顺利落地。",
        position: 6
      }
    ]

    cases.each do |case_data|
      case_study = profile.case_studies.create!(case_data)
      puts "  ✓ 创建案例: #{case_study.title}"
    end

    # 创建荣誉奖项
    Honor.where(profile: profile).destroy_all
    
    honors = [
      {
        title: "全国优秀律师",
        organization: "中华全国律师协会",
        date: "2023年",
        description: "因在商事法律服务领域的突出贡献，被评为全国优秀律师",
        icon_name: "trophy"
      },
      {
        title: "北京市十佳青年律师",
        organization: "北京市律师协会",
        date: "2021年",
        description: "连续三年办案量和客户满意度排名前十",
        icon_name: "award"
      },
      {
        title: "商事诉讼领域杰出贡献奖",
        organization: "中国法学会",
        date: "2020年",
        description: "在复杂商事纠纷解决方面取得显著成就",
        icon_name: "medal"
      },
      {
        title: "最佳法律顾问",
        organization: "企业法务联盟",
        date: "2019年",
        description: "为多家大型企业提供优质法律服务，获客户一致好评",
        icon_name: "certificate"
      }
    ]

    honors.each do |honor_data|
      honor = profile.honors.create!(honor_data)
      puts "  ✓ 创建荣誉: #{honor.title}"
    end

    # 更新客户评价 - 使用数组格式
    profile.update!(
      testimonials: [
        {
          "name" => "王总",
          "title" => "某科技公司CEO",
          "content" => "张律师专业能力强，处理案件非常细致，为我们公司的股权纠纷提供了完美的解决方案。强烈推荐！",
          "rating" => 5
        },
        {
          "name" => "李董",
          "title" => "某集团公司董事长",
          "content" => "合作三年来，张律师团队为我们提供的法律服务非常到位，响应及时，方案专业，是值得信赖的法律伙伴。",
          "rating" => 5
        },
        {
          "name" => "刘女士",
          "title" => "个人客户",
          "content" => "在我最困难的时候，张律师帮助我成功维权，追回了所有损失。感谢张律师的专业和负责！",
          "rating" => 5
        },
        {
          "name" => "陈总",
          "title" => "某上市公司总经理",
          "content" => "张律师不仅法律功底扎实，而且商业思维敏锐，能够从企业角度提供最优解决方案，是难得的好律师。",
          "rating" => 5
        }
      ]
    )

    puts "\n模拟数据创建完成！"
    puts "Profile ID: #{profile.id}"
    puts "访问地址: /cards/#{profile.slug}"
  end
end
